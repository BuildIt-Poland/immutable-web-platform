{
  docker-registry = ./docker-registry.nix;
  argocd = ./argocd.nix;
  virtual-services = ./virtual-services.nix;
  brigade = ./brigade.nix;
  istio-service-mesh = ./istio-service-mesh.nix;
  istio-service-mesh-config = ./istio-service-mesh-config.nix;
  knative-serve = ./knative-serve.nix;
  knative-eventing = ./knative-eventing.nix;
  weavescope = ./weavescope.nix;
  k8s-extension = ./k8s-extension.nix;
  knative = ./knative.nix;
  knative-monitoring = ./knative-monitoring.nix;
  secrets = ./secrets.nix;
  storage = ./storage.nix;
  opa = ./opa.nix;
  bitbucket-event-handler = ./bitbucket-event-handler.nix;
  tekton = ./tekton.nix;
  tekton-crd = ./tekton-crd.nix;
  istio-crd = ./istio-crd.nix;
}