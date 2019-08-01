{
  config, 
  kubenix, 
  ...
}: 
{
  imports = with kubenix.modules; [ 
    k8s 
    docker 
    istio 
    docker-registry
    argocd
    istio-service-mesh
    brigade
    weavescope
  ];

}