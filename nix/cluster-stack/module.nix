{
  config, 
  kubenix, 
  ...
}: 
{
  imports = with kubenix.modules; [ 
    # helm 
    k8s 
    # docker 
    # istio 
    # docker-registry
    # argocd
    # istio-service-mesh
    # brigade
    # weavescope
  ];

  kubernetes.resourceOrder = [
    "CustomResourceDefinition" 
    "Namespace" 
  ];
}