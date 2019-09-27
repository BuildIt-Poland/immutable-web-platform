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

  kubernetes.patches = [
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