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
  ];
  # kubectl expose deployment nginx-ingress-controller -n kube-system --target-port=80 --type=LoadBalancer
  # with nip.io it should dissapear
  kubernetes.imports = [
    # ./ingress/test-fn.yaml
    # ./ingress/bitbucket-gateway.yaml
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