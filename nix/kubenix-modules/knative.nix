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
  functions-ns = namespace.functions;
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  config = {
    # kubernetes.api.namespaces."${functions-ns}"= {
    #   metadata = {
    #     labels = {
    #       "istio-injection" = "enabled";
    #     };
    #   };
    # };

    # kubernetes.crd = [
    #   k8s-resources.knative-crd-json
    # ];

    # kubernetes.static = [
    #   # k8s-resources.knative-serving-json
    # ];
  };
}