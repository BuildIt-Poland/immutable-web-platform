{ 
  config, 
  project-config, 
  lib,
  kubenix, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  functions-ns = namespace.functions.name;
  knative-monitoring-ns = namespace.knative-monitoring.name;
  kn-ns = namespace.knative-serving.name;
  mk-domain = project-config.project.make-sub-domain;
in
{
  imports = with kubenix.modules; [ 
    k8s 
    istio
  ];

  config = {
    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."knative-ingress-gateway" = 
      let
        hosts = [ (mk-domain "*.${functions-ns}") ];
      in
      {
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

    # FIXME this should be in eks module
    kubernetes.api.configmaps = {
      knative-domain = {
        metadata = {
          name = "config-domain";
          namespace = "${kn-ns}";
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