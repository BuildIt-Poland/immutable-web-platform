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

  # default [ "CustomResourceDefinition" "Namespace" ]
  # kubernetes.resourceOrder = []

  # kubernetes.helm.instances.istio = {
  #   namespace = "${istio-ns}";
  #   chart = charts.istio-cni;
  # };

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
}