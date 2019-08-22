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
  knative-monitoring-ns = namespace.knative-monitoring;

  override-namespace = 
      override-static-yaml 
        { metadata.namespace = knative-monitoring-ns; };
in
{
  imports = with kubenix.modules; [ 
    k8s-extension
  ];

  config = {
    kubernetes.api.namespaces."${knative-monitoring-ns}"= {};

    kubernetes.static = [
      (override-namespace k8s-resources.knative-monitoring-json)
    ];
  };
}