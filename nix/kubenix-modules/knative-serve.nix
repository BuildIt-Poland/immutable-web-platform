{ 
  config, 
  project-config, 
  kubenix, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  functions-ns = namespace.functions;
  knative-monitoring-ns = namespace.knative-monitoring;
in
{
  imports = with kubenix.modules; [ 
    k8s 
  ];

  # TODO skaffold is trying ro re
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
  };
} 