{
  config, 
  env-config, 
  pkgs, 
  kubenix, 
  callPackage, 
  ...
}: 
let
  charts = callPackage ./charts.nix {};
  remote-worker = callPackage ./remote-worker.nix {};
  brigade-worker = callPackage ./brigade-worker.nix {};

  namespace = env-config.kubernetes.namespace;
  local-infra-ns = namespace.infra;
  brigade-ns = namespace.brigade;
  istio-ns = namespace.istio;
  ssh-keys = env-config.ssh-keys;
  aws-credentials = env-config.aws-credentials;
in
{
  imports = with kubenix.modules; [ helm k8s docker ];

  docker.images.remote-worker.image = remote-worker;
  docker.images.brigade-worker.image = brigade-worker;

  kubernetes.api.namespaces."${local-infra-ns}"= {};
  kubernetes.api.namespaces."${brigade-ns}"= {};
  kubernetes.api.namespaces."${istio-ns}"= {};

  kubernetes.api.deployments."remote-worker" = {
    metadata.namespace = brigade-ns;
    spec = {
      replicas = 1;
      selector.matchLabels.app = "remote-worker";
      template = {
        metadata.labels.app = "remote-worker";
        spec = {
          # securityContext.fsGroup = 1000;

          containers."remote-worker" = {
            image = "remote-worker:latest"; #config.docker.images.remote-worker.path;
            imagePullPolicy = "Never";
            ports."5000" = {};
            command = [ "nix-serve" ];
            volumeMounts."/_nix/store".name = "build-storage";
          };
          # BUG: it would mount when there will be first build
          volumes."build-storage" = {
            persistentVolumeClaim = {
              claimName = "embracing-nix-docker-k8s-helm-knative-test";
            };
          };
        };
      };
    };
  };

  kubernetes.api.services.remote-worker = {
    spec = {
      ports = [{
        name = "https";
        port = 5000;
      }];
      selector.app = "remote-worker";
    };
  };

  # most likely bitbucket gateway does not handle namespace -> envvar BRIGADE_NAMESPACE
  # perhaps need to pass it somehow during creation -> invetigate
  kubernetes.helm.instances.brigade = {
    namespace = "${brigade-ns}";
    chart = charts.brigade;
    # values = {
    # };
  };

  # INFO json cannot be applied here as it is handled via helm module

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
    # INFO this build storage is global! definition is not the same as for brigade.build-bucket
    # this is cache for NIX!
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
      # volumeBindingMode = "WaitForFirstConsumer";
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
  kubernetes.helm.instances.brigade-project = {
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
        registry = "dev.local";
        name = "brigade-worker";
        tag = "latest";
        pullPolicy = "IfNotPresent";
        # pullPolicy = "Never"; # TODO for dev Never - create global rule! IfNotPresent
      };
      kubernetes = {
        cacheStorageClass = "cache-storage";
        # buildStorageClass = "build-storage";
      };
      secrets = {
        awsAccessKey = aws-credentials.aws_access_key_id;
        awsSecretKey = aws-credentials.aws_secret_access_key;
        awsRegion = aws-credentials.region;
        secrets = builtins.readFile env-config.secrets;
      };
    };
  };
}