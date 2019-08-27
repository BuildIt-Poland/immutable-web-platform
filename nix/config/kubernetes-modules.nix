{config, pkgs, lib, kubenix, shell-modules, inputs, ...}: 
with pkgs.lib;
let
  resources = config.kubernetes.resources;
  priority = resources.priority;

  functions = (import ./modules/functions.nix { inherit pkgs; });

  platform-specific = builtins.getAttr config.kubernetes.target {
    eks = {
      "${priority.high "eks"}" = [ ./modules/eks ];
    };
    minikube = {
      "${priority.high "istio"}" = [ kubenix.modules.istio-service-mesh ];
    };
    gcp = {};
    aks = {};
  };
in
{
  imports = with shell-modules.modules; [
    kubernetes
  ];

  config = {
    kubernetes = {
      target = inputs.kubernetes.target;
      cluster = {
        clean = inputs.kubernetes.clean;
        name = "${config.project.name}-${config.environment.type}-cluster";
      };
      patches.enable = inputs.kubernetes.patches;
      resources = 
        with kubenix.modules;
        let
          modules = {
            "${priority.mid  "knative"}"     = [ knative ];
            "${priority.low  "monitoring"}"  = [ weavescope knative-monitoring ];
            "${priority.low  "gitops"}"      = [ argocd ];
            "${priority.low  "ci"}"          = [ brigade ];
            "${priority.skip "secrets"}"     = [ secrets ];
          } // functions // platform-specific;
          in
          {
            apply = inputs.kubernetes.update;
            save = inputs.kubernetes.save;
            list = modules;
          };

      namespace = {
        functions = "functions";
        argo = "gitops";
        brigade = "ci";
      };
    };
  };
}