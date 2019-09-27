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
    # FIXME temp place
    bitbucket-event-handler
  ];

  config = {
    module.scripts = [
      # FIXME - wip
      # TODO get all functions and create cert based on that
      # TODO apply patch instead of create / delete
      # express-app.dev-functions.$domain \
      # bitbucket-message-dumper.dev-functions.$domain \

      ## TODO MOVE O SECRETS!!! istio-system

      ## TODO iterate all project-config.modules.kubernetes.express-app.raw.kubernetes.api.ksvc
      (pkgs.writeShellScriptBin "patch-knative-nip-domain" ''
        ${pkgs.lib.log.important "Patching knative domain"}
        ${pkgs.lib.log.info "Run 'minikube tunnel' first."}

        ip=$(get-istio-ingress-lb-port)
        domain=$ip.nip.io

        ${pkgs.lib.log.important "Generating certs"}
        tmpfile=$(mktemp -d)

        (cd $tmpfile && ${pkgs.mkcert}/bin/mkcert -install)
        (cd $tmpfile && ${pkgs.mkcert}/bin/mkcert \
          $domain \
          ${functions-ns}.$domain \
          localhost)
        
        ${pkgs.kubectl}/bin/kubectl delete --namespace istio-system secret istio-ingressgateway-certs --wait
        ${pkgs.kubectl}/bin/kubectl create --namespace istio-system secret tls istio-ingressgateway-certs \
          --key $tmpfile/$domain+2-key.pem \
          --cert $tmpfile/$domain+2.pem

        ${pkgs.kubectl}/bin/kubectl patch \
          cm config-domain -n knative-serving \
          -p '{"data":{"'"$domain"'":""}}'
      '')
    ];
     
     # TODO
    kubernetes.api.secrets = {
      istio-ingressgateway = {
        metadata.name = "istio-ingressgateway-certs";
        metadata.namespace = "istio-system";
        type = "kubernetes.io/tls";
        data = {
          "tls.key" = "";
          "tls.cert" = "";
        };
      };
    };

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