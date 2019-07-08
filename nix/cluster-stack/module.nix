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
  # charts = callPackage ./charts.nix {};

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
  monitoring-gateway = config.kubernetes.monitoring.gateway;
in
{
  imports = with kubenix.modules; [ helm k8s docker istio ];

  kubernetes.api.namespaces."${local-infra-ns}"= {};
  kubernetes.api.namespaces."${istio-ns}"= {};
  kubernetes.api.namespaces."${functions-ns}"= {
    metadata = {
      labels = {
        "istio-injection" = "enabled";
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

  # as kind has an alias this is not required - super cool!
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

  # Check this -> https://kubernetes.io/docs/concepts/services-networking/service/#externalname
  # https://github.com/triggermesh/knative-local-registry/blob/master/sysadmin/nodes-etc-hosts-update.yaml
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

        inherit monitoring-gateway;
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
      global = {
        disablePolicyChecks = true;
        proxy.autoInject = "disabled";
        sidecarInjectorWebhook.enabled = true;
        sidecarInjectorWebhook.enableNamespacesByDefault = true;
      };
    };
  };

  kubernetes.customResources = [
    (create-istio-cr "attributemanifest")
    (create-istio-cr "kubernetes")
    (create-istio-cr "rule")
    (create-istio-cr "handler")
  ];

  # default [ "CustomResourceDefinition" "Namespace" ]
  # kubernetes.resourceOrder = []
}