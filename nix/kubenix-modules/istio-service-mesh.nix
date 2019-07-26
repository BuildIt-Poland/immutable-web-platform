{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  istio-ns = namespace.istio;

  virtual-services-gateway = config.kubernetes.virtual-services.gateway;

  create-istio-cr = kind: {
    group = "config.istio.io";
    version = "v1alpha2";
    kind = kind;
    description = "";
  } ;
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
    virtual-services
  ];

  config = {
    kubernetes.api.namespaces."${istio-ns}"= {};

    kubernetes.helm.instances.istio = 
    let
      isio-sds = {
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
        certmanager.enabled = true;
        certmanager.email = "damian.baar@wipro.com";
        global = {
          controlPlaneSecurityEnabled = false;
          mtls.enabled = false;
          configValidation = true;
          sds = {
            enabled = false;
            udsPath = "unix:/var/run/sds/uds_path";
            useNormalJwt = true;
          };
          proxy.clusterDomain = "dev.cluster";
          k8sIngress.gatewayName = "ingressgateway";
          k8sIngress.enabled = true;
          k8sIngress.enableHttps = false;
        };
      };
    in
    {
      namespace = "${istio-ns}";
      chart = k8s-resources.istio;
      values = {
        gateways = {
          istio-ingressgateway = {
            # sds.enabled = true;
            type = "LoadBalancer";
            autoscaleMin = 1;
            autoscaleMax = 1;
            resources.requests = {
              cpu = "500m";
              memory="256Mi";
            };
          };

          virtual-services = virtual-services-gateway;
        };

        istio_cni.enabled = false;
        mixer.policy.enabled = false;
        mixer.telemetry.enabled = true;
        mixer.adapters.prometheus.enabled = false;
        # https://github.com/istio/istio/issues/7675#issuecomment-415447894
        mixer.adapters.useAdapterCRDs = true;
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
      (create-istio-cr "instance")
    ];
  };
}
