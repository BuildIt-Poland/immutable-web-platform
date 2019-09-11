# https://istio.io/docs/reference/config/policy-and-telemetry/adapters/opa/
# https://github.com/open-policy-agent/opa-istio-plugin
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources ? pkgs.k8s-resources,
  project-config,
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
in
{
  imports = with kubenix.modules; [ 
    k8s
    istio
  ];

  options = {
    policy = lib.mkOption {
      default = [];
    };
  };

  config = {
    kubernetes.api.namespaces."policy"= {};

    # kubernetes.imports = 
    #   builtins.map 
    #     (x: ./opa + "/${x}") 
    #     (builtins.attrNames 
    #       (builtins.readDir ./opa));
  };
}
# opa test istio https://github.com/istio/istio/pull/2229/files
# https://www.youtube.com/watch?v=BeZMahXg9Tg
/*
authorized {
  input["target.service"] = "sth.namespace.svc.cluster.local"
}
*/
