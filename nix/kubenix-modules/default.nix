{
  docker-registry = ./docker-registry.nix;
  argocd = ./argocd.nix;
  virtual-services = ./virtual-services.nix;
  brigade = ./brigade.nix;
  istio-service-mesh = ./istio-service-mesh.nix;
  knative-serve = ./knative-serve.nix;
  weavescope = ./weavescope.nix;
}