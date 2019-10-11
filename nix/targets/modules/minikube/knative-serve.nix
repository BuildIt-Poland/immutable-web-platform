{ 
  config, 
  pkgs,
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
    k8s-extension
  ];

  config = {
    # kubernetes.patches = [
    module.scripts = [
      # TODO get all functions and create cert based on that
      # TODO apply patch instead of create / delete

      # with minikube tunel
      # ${pkgs.lib.log.info "Run 'minikube tunnel' first."}
      (pkgs.writeShellScriptBin "patch-knative-nip-domain" ''
        ${pkgs.lib.log.important "Patching knative domain"}

        ip=$(get-istio-ingress-lb)
        domain=$ip.nip.io

        ${pkgs.kubectl}/bin/kubectl patch \
          cm config-domain -n knative-serving \
          -p '{"data":{"'"$domain"'":""}}'
      '')
    ];
     
    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."knative-ingress-gateway" = 
      let
        hosts = [ "*" ];
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