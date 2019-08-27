{ 
  config, 
  project-config, 
  lib,
  kubenix, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  functions-ns = namespace.functions;
  knative-monitoring-ns = namespace.knative-monitoring;
  kn-ns = namespace.knative-serving;
  mk-domain = project-config.project.make-sub-domain;
in
{
  imports = with kubenix.modules; [ 
    k8s 
    istio
  ];

  options = {
    ssl = {
      default = true;
    };
    hosts = lib.mkOption {
      default = [];
    };
  };

  config = {
    kubernetes.customResources = [
      {
        group = "serving.knative.dev";
        version = "v1alpha1";
        kind = "Service";
        description = "";
        resource = "knative-serve-service";
      }
    ];

    # overridings - argo most likely will be shouting about duplicate
    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."knative-ingress-gateway" = 
      let
        hosts = [ (mk-domain "*.${functions-ns}") ];
      in
      {
        # BUG: this metadata should be taken from name
        metadata = {
          name = "knative-ingress-gateway";
          namespace = kn-ns;
        };
        spec = {
          selector.istio = "ingressgateway";
          servers = [
            {
            inherit hosts;

            port = {
              number = 80;
              name = "http-system";
              protocol = "HTTP";
            };
          } 
          {
            inherit hosts;

            port = {
              number = 443;
              name = "https-system";
              protocol = "HTTPS";
            };
            tls = {
              mode = "SIMPLE";
              privateKey = "sds";
              serverCertificate = "sds";
              credentialName = "ingress-cert"; # FROM EKS-module
            };
          }];
        };
      };
    };

    kubernetes.api.configmaps = {
      knative-domain = {
        metadata = {
          name = "config-domain";
          namespace = "${kn-ns}";
          labels = {
            # "networking.knative.dev/certificate-provider" = "cert-manager";
            # "certmanager.k8s.io/cluster-issuer" = "cert-issuer";
          };
        };
        data = {
          "${project-config.project.make-sub-domain ""}" = "";
        };
      };
      knative-cert = {
        metadata = {
          name = "config-certmanager";
          namespace = "${kn-ns}";
        };
        data = {
          secretName = "ingress-cert";
          issuerRef = ''
            name: cert-issuer
            kind: ClusterIssuer
          '';
          autoTLS = "Enabled";
          httpprotocol = "redirected";
          solverconfig = ''
            dns01:
              provider: route53
          '';
        };
      };
    };
  };
} 