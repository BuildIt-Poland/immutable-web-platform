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
    inherit kind;
    group = "config.istio.io";
    version = "v1alpha2";
    description = "";
  };

  create-cert-mgr-cr = kind: {
    inherit kind;
    group = "certmanager.k8s.io";
    version = "v1alpha1";
    description = "";
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
    virtual-services
    k8s-extension
  ];

  # FIXME instance cannot be imported as will be duplicated
  # modules configuration + instance
  # move this to configuration - to be able to import it everywhere, i.e. eks-cluster
  options.service-mesh = {
    virtual-services = lib.mkOption {
      default = {};
    };
    overridings = lib.mkOption {
      default = {};
    };
  };

  config = {
    kubernetes.api.namespaces."${istio-ns}"= {};

    kubernetes.crd = [
      (k8s-resources.istio-init-json ({certmanager.enabled = true;}))
    ];

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
        certmanager.email = project-config.project.author-email;
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
          k8sIngress.enableHttps = true; # FIXME should be target related
        };
      };
    in
    {
      namespace = "${istio-ns}";
      chart = k8s-resources.istio;
      values = {
        gateways = 
          let
            annotations = name: {
              # external-dns.alpha.kubernetes.io/hostname: nginx.external-dns-test.my-org.com
              serviceAnnotations = 
                {type = "external";} //
                (project-config.load-balancer.service-annotations name);
            };
          in
          {
            istio-ingressgateway = {
              sds.enabled = true;
              type = "LoadBalancer";
              autoscaleMin = 1;
              autoscaleMax = 1;
              resources.requests = {
                cpu = "500m";
                memory="256Mi";
              };
            } // (annotations "services");
            # virtual-services = virtual-services-gateway // (annotations "monitoring");
          };

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
        certmanager.email = project-config.project.author-email;

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
          # https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/values.yaml#L368
          defaultNodeSelector = {
            "kubernetes.io/lifecycle"= "on-demand";
          };
          # TODO
          # defaultTolerations = [];
          disablePolicyChecks = true;
          proxy.autoInject = "disabled";
          sidecarInjectorWebhook.enabled = true;
          sidecarInjectorWebhook.enableNamespacesByDefault = true;
          k8sIngress.gatewayName = "ingressgateway";
          k8sIngress.enabled = true;
          k8sIngress.enableHttps = true; # FIXME should be target related\

          sds = {
            enabled = true;
            udsPath = "unix:/var/run/sds/uds_path";
            useNormalJwt = true;
          };
        };
      };
    };

    kubernetes.customResources = [
      (create-istio-cr "attributemanifest")
      (create-istio-cr "kubernetes")
      (create-istio-cr "rule")
      (create-istio-cr "handler")
      (create-istio-cr "instance")

      # required to allow (kubenix limitation / validation) -> certmanager.enabled = true;
      (create-cert-mgr-cr "certmanager")
      (create-cert-mgr-cr "ClusterIssuer")
    ];
  };
}
