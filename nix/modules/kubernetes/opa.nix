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
    istio-crd
  ];

  options = {
    policy = {
      folder = lib.mkOption {
        default = ../../../policy/runtime;
      };
    };
  };

  config = {
    kubernetes.api.namespaces."policy"= {};

    kubernetes.imports = [
      ./opa/istio-authorization-mapping.yaml
    ];

    kubernetes.api.handler.opa = {
      metadata = {
        name = "opa";
        namespace = "istio-system";
      };
      spec = {
        compiledAdapter = "opa";
        params = {
          policy = 
            ((builtins.map 
              builtins.readFile
              (builtins.filter (f: 
                   !(lib.hasSuffix ".mock.rego" f)
                && !(lib.hasSuffix ".test.rego" f)
                )
                (builtins.map 
                  (x: config.policy.folder + "/${x}") 
                  (builtins.attrNames 
                    (builtins.readDir config.policy.folder)))))
            ++ 
            [''
              package nix
              ns = ${builtins.toJSON 
                      (builtins.mapAttrs (n: v: v.name) namespace)}
            ''
            ]);
          failClose = true;
          checkMethod = "data.mixerauthz.allow";
        };
      };
    };
    kubernetes.api.rule.authorization = {
      metadata = {
        name = "authorization";
        namespace = "istio-system";
      };
      spec.actions = [{
        handler = "opa.istio-system";
        instances = ["authzinstance"];
      }];
    };
  };
}
# opa test istio https://github.com/istio/istio/pull/2229/files
# https://www.youtube.com/watch?v=BeZMahXg9Tg
/*
authorized {
  input["target.service"] = "sth.namespace.svc.cluster.local"
}
*/
