{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
with kubenix.lib.helm;
let
  namespace = project-config.kubernetes.namespace;
  infra-ns = namespace.infra;
in
{
  imports = with kubenix.modules; [ 
    k8s
  ];

  config = {
    kubernetes.api.namespaces."${infra-ns.name}"= {
      metadata = lib.recursiveUpdate {} infra-ns.metadata;
    };
  };
}