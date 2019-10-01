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
  ];

  config = {
    kubernetes.customResources = [
      {
        group = "serving.knative.dev";
        version = "v1";
        kind = "Service";
        description = "";
        resource = "ksvc";
      }

      {
        group = "messaging.knative.dev";
        version = "v1alpha1";
        kind = "Channel";
        description = "";
        resource = "kchannel";
      }
    ];
  };
} 