{ 
  config, 
  lib, 
  kubenix, 
  pkgs,
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  istio-ns = namespace.istio;
  service-mesh-config = config.kubernetes.network-mesh;

  create-istio-cr = kind: {
    inherit kind;

    group = "config.istio.io";
    version = "v1alpha2";
    description = "";
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
    k8s-extension
  ];

  options.kubernetes.network-mesh = {
    enable = lib.mkOption {
      default = true;
    };
    helm = lib.mkOption {
      default = {};
    };
    namespace = lib.mkOption {
      default = {};
    };
    crd = lib.mkOption {
      default = {};
    };
  };

  config = (lib.mkIf config.kubernetes.network-mesh.enable {
    kubernetes.api.namespaces."${istio-ns}" = service-mesh-config.namespace;

    kubernetes.crd = [
      (k8s-resources.istio-init-json service-mesh-config.crd)
    ];

    kubernetes.patches = [];

    kubernetes.helm.instances.istio = 
      {
        namespace = "${istio-ns}";
        chart = k8s-resources.istio;
        values = lib.recursiveUpdate ({
          gateways = {
            istio-ingressgateway = {
              type = "LoadBalancer";
              autoscaleMin = 1;
              autoscaleMax = 1;
              resources.requests = {
                cpu = "500m";
                memory="256Mi";
              };
              serviceAnnotations = {};
            };
          };

          istio_cni.enabled = false;
          mixer.policy.enabled = false;
          mixer.telemetry.enabled = true;
          mixer.adapters.prometheus.enabled = false;
          # https://github.com/istio/istio/issues/7675#issuecomment-415447894
          # mixer.adapters.useAdapterCRDs = true;
          grafana.enabled = false;
          pilot.autoscaleMin = 2;
          pilot.traceSampling = 100;
          global = {
            proxy.autoInject = "disabled";
            sidecarInjectorWebhook.enabled = true;
            sidecarInjectorWebhook.enableNamespacesByDefault = true;
            k8sIngress.gatewayName = "ingressgateway";
            k8sIngress.enabled = false;
          };
        }) service-mesh-config.helm;
      };

    kubernetes.customResources = [
      (create-istio-cr "attributemanifest")
      (create-istio-cr "kubernetes")
      (create-istio-cr "rule")
      (create-istio-cr "handler")
      (create-istio-cr "instance")
    ];
  });
}
