{
  config, 
  env-config, 
  pkgs, 
  kubenix, 
  callPackage, 
  brigade-extension,
  remote-worker,
  ...
}: 
let
  charts = callPackage ./charts.nix {};

  namespace = env-config.kubernetes.namespace;

  local-infra-ns = namespace.infra;
  brigade-ns = namespace.brigade;
  istio-ns = namespace.istio;
  functions-ns = namespace.functions;
  knative-monitoring-ns = namespace.knative-monitoring;

  ssh-keys = env-config.ssh-keys;
  aws-credentials = env-config.aws-credentials;

  create-istio-cr = kind: {
    group = "config.istio.io";
    version = "v1alpha2";
    kind = kind;
    description = "";
  };
in
{
  imports = with kubenix.modules; [ helm k8s docker istio ];

  docker.images.brigade-worker.image = remote-worker.docker-image;
  docker.images.brigade-extension.image = brigade-extension.docker-image;

  kubernetes.api.namespaces."${local-infra-ns}"= {};
  kubernetes.api.namespaces."${brigade-ns}"= {};
  kubernetes.api.namespaces."${istio-ns}"= {};
  kubernetes.api.namespaces."${functions-ns}"= {
    metadata = {
      labels = {
        "istio-injection" = "enabled";
      };
    };
  };

  # default [ "CustomResourceDefinition" "Namespace" ]
  # kubernetes.resourceOrder = []

  kubernetes.helm.instances.brigade = {
    namespace = "${brigade-ns}";
    chart = charts.brigade;
  };
  
  kubernetes.helm.instances.istio = {
    namespace = "${istio-ns}";
    chart = charts.istio;
    values = {
      gateways = {
        istio-ingressgateway = {
          type = "NodePort";
          autoscaleMin = 1;
          autoscaleMax = 1;
          resources.requests = {
            cpu = "500m";
            memory="256Mi";
          };
        };

        monitoring-gateway = {
          enabled = true;
          labels = {
            app = "monitoring-gateway";
            istio = "monitoring-ingressgateway";
          };
          type = "NodePort";
          ports = [{
            port = 15300;
            targetPort = 15300;
            name = "grafana-port";
          } {
            port = 15301;
            targetPort = 15301;
            name = "weavescope-port";
          } {
            port = 15302;
            targetPort = 15302;
            name = "zipkin-port";
          } ];
        };
      };

      mixer.policy.enabled = true;
      mixer.telemetry.enabled = true;
      mixer.adapters.prometheus.enabled = false;
      grafana.enabled = false;
      pilot.autoscaleMin = 2;
      pilot.traceSampling = 100;
      global = {
        disablePolicyChecks = true;
        proxy.autoInject = "disabled";
        sidecarInjectorWebhook.enabled = true;
        sidecarInjectorWebhook.enableNamespacesByDefault = true;
      };
    };
  };

  # TODO should be module
  kubernetes.api."networking.istio.io"."v1alpha3" = {
    Gateway."grafana-gateway" = {
      # BUG: this metadata should be taken from name
      metadata = {
        name = "grafana-gateway";
      };
      spec = {
        selector.istio = "monitoring-ingressgateway";
        servers = [{
          port = {
            number = 15301;
            name = "http2-weavescope";
            protocol = "HTTP2";
          };
          hosts = ["*"];
        } {
          port = {
            number = 15300;
            name = "http2-grafana";
            protocol = "HTTP2";
          };
          hosts = ["*"];
        } {
          port = {
            number = 15302;
            name = "http2-zipkin";
            protocol = "HTTP2";
          };
          hosts = ["*"];
        }];
      };
    };
    DestinationRule.grafana = {
      metadata = {
        name = "destination-rule-grafana";
      };
      spec = {
        host = "grafana.${knative-monitoring-ns}.svc.cluster.local";
        trafficPolicy.tls.mode = "DISABLE";
      };
    };
    VirtualService.grafana = {
      metadata = {
        name = "virtualservice-grafana";
      };
      spec = {
        hosts = ["*"];
        gateways = ["grafana-gateway"];
        http = [
        {
          match = [
            # { port = 15301; }
            { url.prefix.match = "/scope"; }
          ];
          route = [{
            destination = {
              host = "weave-scope-app.weave.svc.cluster.local";
              port.number = 80; # take this port from somewhere - create ports map
            };
          }];
        }
        {
          match = [
            { port = 15302; }
            # { url.prefix.match = "/"; }
          ];
          route = [{
            destination = {
              host = "zipkin.istio-system.svc.cluster.local";
              port.number = 9411; # take this port from somewhere - create ports map
            };
          }];
        }
        {
          match = [
            { port = 15300; }
            # { headers = {
            #   app.exact = "grafana";
            # };}
          ];
          route = [{
            destination = {
              host = "grafana.${knative-monitoring-ns}.svc.cluster.local";
              port.number = 30802; # take this port from somewhere - create ports map
            };
          }];
        } 
        ];
      };
    };
  };

  kubernetes.customResources = [
    (create-istio-cr "attributemanifest")
    (create-istio-cr "kubernetes")
    (create-istio-cr "rule")
    (create-istio-cr "handler")
  ];

  kubernetes.helm.instances.brigade-bitbucket-gateway = {
    namespace = "${brigade-ns}";
    name = "brigade-bitbucket-gateway";
    chart = charts.brigade-bitbucket;
    values = {
      rbac = {
        enabled = true;
      };
      bitbucket = {
        name = "brigade-bitbucket-gateway";
        service = {
          name = "service";
          type = "NodePort";
        };
      };
    };
  };

  kubernetes.api.storageclasses = {
    build-storage = {
      metadata = {
        namespace = brigade-ns;
        name = "build-storage";
        annotations = {
          "storageclass.beta.kubernetes.io/is-default-class" = "false"; 
        };
        labels = {
          "addonmanager.kubernetes.io/mode" = "EnsureExists";
          # exec
        };
      };
      reclaimPolicy = "Retain";
      provisioner = "kubernetes.io/host-path";
    };

    cache-storage = {
      metadata = {
        namespace = brigade-ns;
        name = "cache-storage";
        annotations = {
          "storageclass.beta.kubernetes.io/is-default-class" = "false"; 
        };
        labels = {
          "addonmanager.kubernetes.io/mode" = "EnsureExists";
        };
      };
      reclaimPolicy = "Retain";
      provisioner = "kubernetes.io/host-path";
    };
  };

  # https://github.com/brigadecore/charts/blob/master/charts/brigade-project/values.yaml
  kubernetes.helm.instances.brigade-project = 
  let
    cfg = config.docker.images;
    extension = cfg.brigade-extension;
    worker = cfg.brigade-worker;
  in
  {
    namespace = "${brigade-ns}";
    name = "brigade-project";
    chart = charts.brigade-project;
    values = {
      project = env-config.brigade.project-name;
      repository = env-config.brigade.project-name; # repository.location is too long # TODO check if it would work with gateway now ...
      # repository = env-config.repository.location;
      cloneURL = env-config.repository.git;
      vcsSidecar = "brigadecore/git-sidecar:latest";
      sharedSecret = env-config.brigade.sharedSecret;
      defaultScript = builtins.readFile env-config.brigade.pipeline; 
      sshKey = builtins.readFile ssh-keys.bitbucket.priv;
      workerCommand = "yarn build-start";
      worker = {
        registry = if env-config.is-dev then "" else env-config.docker.registry;
        name = extension.name;
        tag = extension.tag;
        # actually should be never but it seems that they are applying to this policy to sidecar as well
        pullPolicy = "IfNotPresent"; 
      };
      kubernetes = {
        cacheStorageClass = "cache-storage";
        buildStorageClass = "build-storage";
      };
      secrets = {
        awsAccessKey = aws-credentials.aws_access_key_id;
        awsSecretKey = aws-credentials.aws_secret_access_key;
        awsRegion = aws-credentials.region;
        sopsSecrets = builtins.readFile env-config.secrets;
        cacheBucket = env-config.s3.worker-cache;
        workerDockerImage = "${worker.path}";
      };
    };
  };
}