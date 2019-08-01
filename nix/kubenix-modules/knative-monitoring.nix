{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
{
  imports = with kubenix.modules; [ 
    k8s-extension
  ];

  config = {
    kubernetes.static = [
      k8s-resources.knative-monitoring-json
    ];
  };
}