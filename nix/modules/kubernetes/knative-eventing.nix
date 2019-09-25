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

  override = 
    resource: 
    mapper: 
      pkgs.writeText "overrided-json"
        (builtins.toJSON 
          (builtins.filter (v: v != null) 
          (builtins.map mapper (builtins.fromJSON (builtins.readFile resource)))));
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
      make-image 
        ["cmd/controller"] 
        "bitbucket-controller" 
        "controller";

    docker.images.bitbucket-receive-adapter.image = 
      make-image 
        ["cmd/receive_adapter"] 
        "bitbucket-receive-adapter" 
        "receive_adapter";

    kubernetes.static = [
      # FIXME make me easier to follow
      (override k8s-resources.knative-eventing-bitbucket-source-json (v: 
          if (v.kind == "StatefulSet" && v.metadata.name == "bitbucket-controller-manager") then
            (lib.recursiveUpdate v { 
              spec.template.spec.containers = 
                let
                  images = config.docker.images;
                  controller = images.bitbucket-source-controller;
                  receiver = images.bitbucket-receive-adapter;

                  containers = v.spec.template.spec.containers;
                  first = lib.head containers;
                in
                [
                  (lib.recursiveUpdate 
                    first
                    { image = controller.path; 
                      imagePullPolicy = project-config.kubernetes.imagePullPolicy;
                      env = [
                        ((lib.head first.env) // { value = receiver.path; })
                      ];
                    }
                  )
                ];
            })
          else v
      ))

      k8s-resources.knative-eventing-json
    ];
  };
}