{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
with kubenix.lib.helm;
let
  namespace = project-config.kubernetes.namespace;
  functions-ns = namespace.functions;
  knative-eventing-ns = "knative-eventing";
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  config = {
    # kubernetes.api.namespaces."${functions-ns.name}"= {
    #   metadata = lib.recursiveUpdate {} functions-ns.metadata;
    # };

    kubernetes.static = [
      k8s-resources.knative-eventing-json
    ];
  };
}