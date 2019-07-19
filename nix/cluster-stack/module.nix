{
  config, 
  env-config, 
  pkgs, 
  kubenix, 
  charts,
  callPackage, 
  ...
}: 
let
  namespace = env-config.kubernetes.namespace;

  local-infra-ns = namespace.infra;
  brigade-ns = namespace.brigade;
  istio-ns = namespace.istio;
  argo-ns = namespace.argo;
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
  virtual-services = config.kubernetes.virtual-services.gateway;
in
{
  imports = with kubenix.modules; [ helm k8s docker istio ];

  # iterate over all namespaces
  kubernetes.api.namespaces."${local-infra-ns}"= {};
  kubernetes.api.namespaces."${istio-ns}"= {};
  kubernetes.api.namespaces."${argo-ns}"= {};
  kubernetes.api.namespaces."${functions-ns}"= {
    metadata = {
      labels = {
        "istio-injection" = "enabled";
      };
    };
  };

  # INFO 1: this ns is dedicated for cert-manager - workaround for now and keeping it in default
  # INFO 2: kubectl not happy patching kube-system 
  # Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
  # however it is working: namespace/kube-system configured
  kubernetes.api.namespaces."kube-system"= {
    metadata = {
      labels = {
        "certmanager.k8s.io/disable-validation" = "true";
      };
    };
  };

  kubernetes.helm.instances.docker-registry = {
    namespace = "${local-infra-ns}";
    chart = charts.docker-registry;
    values = 
      let
        registry = env-config.docker.local-registry;
      in
      {
        service.type = "ClusterIP";
      };
  };

  # TODO
  # ARGO password:  https://github.com/argoproj/argo-cd/issues/829
  # create repo
  # create application
  # there is a cli - a bit regret that this is not a kubernetes resource
  # kubernetes.helm.instances.argo-cd = {
  #   namespace = "${argo-ns}";
  #   chart = charts.argo-cd;
  #   values ={
  #     # config.repositories = {};
  #     # ingress = {
  #     #   enabled = true;
  #     #   path = "/";
  #     #   annotations = {
  #     #     "kubernetes.io/ingress.class" = "istio";
  #     #   };
  #     #   hosts = [
  #     #     "localhost"
  #     #     # "argocd.example.com"
  #     #   ];
  #     # };
  #     config = {
  #       # https://argoproj.github.io/argo-cd/user-guide/diffing/#application-level-configuration
  #       # https://github.com/argoproj/argo-helm/blob/master/charts/argo-cd/values.yaml#L127
  #       # resourceCustomizations = {
  #       #   ignoreDifferences = [{
  #       #     jsonPointers = [
  #       #       "metadata/labels/kubenix/hash"
  #       #     ];
  #       #   }];
  #       # };
  #     };
  #   };
  # };

  # https://github.com/helm/charts/tree/master/stable/cert-manager#installing-the-chart

  # Issue with kubenix -> if namespace is defined in resource then definition cannot be merged
  # affected resource: https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/webhook/templates/rbac.yaml#L35
  kubernetes.helm.instances.cert-manager = {
    # namespace = "${istio-ns}";
    namespace = "kube-system";
    chart = charts.cert-manager;
    values = {
      webhook.enabled = true;
    };
  };

  # TODO expose port 80 as some static value to provide it to kind
  kubernetes.helm.instances.istio = {
    namespace = "${istio-ns}";
    chart = charts.istio;
    values = {
      gateways = {
        istio-ingressgateway = {
          sds.enabled = true;
          type = "NodePort";
          autoscaleMin = 1;
          autoscaleMax = 1;
          resources.requests = {
            cpu = "500m";
            memory="256Mi";
          };
        };

        inherit virtual-services;
      };

      istio_cni.enabled = true;
      mixer.policy.enabled = true;
      mixer.telemetry.enabled = true;
      mixer.adapters.prometheus.enabled = false;
      # https://github.com/istio/istio/issues/7675#issuecomment-415447894
      mixer.adapters.useAdapterCRDs = false;
      grafana.enabled = false;
      pilot.autoscaleMin = 2;
      pilot.traceSampling = 100;
      # TODO: knative define in own zipkin setup - check and think how to merge these definition to avoid warning in argo
      # tracing.enabled = true;
      # tracing.provider = "zipkin";
      # https://raw.githubusercontent.com/istio/istio/release-1.2/install/kubernetes/helm/istio/values-istio-sds-auth.yaml
      nodeagent = {
        enabled =  true;
        image =  "node-agent-k8s";
        env = {
          CA_PROVIDER =  "Citadel";
          CA_ADDR =  "istio-citadel:8060";
          VALID_TOKEN = true;
        };
      };
      global = {
        controlPlaneSecurityEnabled = false;
        mtls.enabled = true;
        sds = {
          enabled = true;
          udsPath = "unix:/var/run/sds/uds_path";
          useNormalJwt = true;
        };
        k8sIngress.enabled = true;
        k8sIngress.enableHttps = true;
        disablePolicyChecks = true;
        proxy.autoInject = "disabled";
        sidecarInjectorWebhook.enabled = true;
        sidecarInjectorWebhook.enableNamespacesByDefault = true;
      };
    };
  };

  kubernetes.customResources = [
    {
      group = "certmanager.k8s.io";
      version = "v1alpha1";
      kind = "Certificate";
    }
    {
      group = "certmanager.k8s.io";
      version = "v1alpha1";
      kind = "Issuer";
    }
    (create-istio-cr "attributemanifest")
    (create-istio-cr "kubernetes")
    (create-istio-cr "rule")
    (create-istio-cr "handler")
  ];

  # default [ ]
  kubernetes.resourceOrder = [
    "CustomResourceDefinition" 
    "Namespace" 
  ];

  # DOCKER PROXY REGISTRY - ingress would be handy
  # kubernetes.helm.instances.kube-registry-proxy = {
  #   namespace = "${local-infra-ns}";
  #   chart = charts.kube-registry-proxy;
  #   values = {
  #     registry.host = "docker-registry.local-infra.svc.cluster.local";
  #     registry.port = env-config.docker.local-registry.clusterPort;
  #     # hostPort
  #     # hostIp
  #   };
  # };
}