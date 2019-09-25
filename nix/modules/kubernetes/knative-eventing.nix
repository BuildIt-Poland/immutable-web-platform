{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
with kubenix.lib.helm;
let
  namespace = project-config.kubernetes.namespace;
  functions-ns = namespace.functions;
  knative-eventing-ns = "knative-eventing";
  make-image = pkgs.callPackage ./knative-eventing/source/bitbucket/image.nix {};
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    docker
  ];

  config = {
    # kubernetes.api.namespaces."${functions-ns.name}"= {
    #   metadata = lib.recursiveUpdate {} functions-ns.metadata;
    # };
    docker.images.bitbucket-source-controller.image = 
      make-image ["cmd/controller"] "bitbucket-controller";

    docker.images.bitbucket-receive-adapter.image = 
      make-image ["cmd/receive_adapter"] "bitbucket-receive-adapter";

    kubernetes.static = [
      k8s-resources.knative-eventing-json
    ];
  };
}