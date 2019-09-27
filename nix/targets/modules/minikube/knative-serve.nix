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
    # kubernetes.api.secrets = {
    #   istio-ingressgateway = {
    #     metadata.name = "istio-ingressgateway";
    #     metadata.namespace = "istio-system";
    #     data.key = "dsadas";
    #     data.cert = "dsadas";
    #   };
    # };

    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."knative-ingress-gateway" = 
      let
        hosts = [ (mk-domain "*") ];
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
              privateKey = "/etc/istio/ingressgateway-certs/tls.key";
              serverCertificate = "/etc/istio/ingressgateway-certs/tls.crt";
            };
          }];
        };
      };
    };
  };
} 