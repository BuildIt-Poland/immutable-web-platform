{
  docker-registry = ./docker-registry.nix;
  argocd = ./argocd.nix;
  virtual-services = ./virtual-services.nix;
  brigade = ./brigade.nix;
  istio-service-mesh = ./istio-service-mesh.nix;
  knative-serve = ./knative-serve.nix;
  weavescope = ./weavescope.nix;
  k8s-extension = ./k8s-extension.nix;
  knative = ./knative.nix;
  knative-monitoring = ./knative-monitoring.nix;
  secrets = ./secrets.nix;
  eks-cluster = ./eks-cluster.nix;
}