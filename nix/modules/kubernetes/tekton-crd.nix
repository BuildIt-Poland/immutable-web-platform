{ 
  config, 
  lib, 
  kubenix, 
  pkgs,
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;

  create-istio-cr = kind: {
    inherit kind;

    group = "tekton.dev";
    version = "v1alpha1";
    description = "";
    resource = kind;
  };
in {
  imports = with kubenix.modules; [ 
    k8s
  ];

  config = {
    kubernetes.customResources = [
      (create-istio-cr "ClusterTask")
      (create-istio-cr "Pipeline")
      (create-istio-cr "PipelineRun")
      (create-istio-cr "PipelineResource")
      (create-istio-cr "TaskRun")
      (create-istio-cr "Task")
    ];
  };
}