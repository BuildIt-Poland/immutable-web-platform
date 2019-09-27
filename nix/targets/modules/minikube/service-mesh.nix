# https://eksworkshop.com/scaling/deploy_hpa/
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources ? pkgs.k8s-resources,
  project-config,
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  eks-ns = "eks";
  kn-serving = namespace.knative-serving;
  istio-ns = namespace.istio;
  functions-ns = namespace.functions;
in
{
  imports = with kubenix.modules; [ 
    # not the best flexibility - this will be included in the same yaml file
    # however it is overriding so make sense - better would be eks-service-mesh and separate file?
    istio-service-mesh
    k8s-extension
  ];

  kubernetes.imports = [
  ];

  module.scripts = [
    (pkgs.writeShellScriptBin "get-istio-ingress-lb-port" ''
      ${pkgs.kubectl}/bin/kubectl -n istio-system \
        get service istio-ingressgateway \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    '')
  ];

# IMPORTANT FIXME gatewy is wrong
# FIXXXXXIT!!!
# kubectl edit -n knative-serving gateway knative-ingress-gateway
  # FIXME
  kubernetes.patches = [
    (pkgs.writeShellScriptBin "patch-knative-domain" ''
      ${pkgs.lib.log.important "Patching knative domain"}
      ${pkgs.lib.log.info "It is advised to run 'minikube tunnel' first."}

      ip=$(get-istio-ingress-lb-port)

      ${pkgs.kubectl}/bin/kubectl patch \
        cm config-domain -n knative-serving \
        -p '{"data":{"'"$ip"'.nip.io":"","nip.io":null}}'
    '')
  ];


  kubernetes.network-mesh = {
    enable = true;

    helm = {
      gateways = {
        istio-ingressgateway = {
          type = "LoadBalancer";
        };
      };

      global = {
        k8sIngress.gatewayName = "ingressgateway";
      };
    };
  };
}