{config, pkgs, lib, kubenix, integration-modules, inputs, ...}: 
with pkgs.lib;
let
  resources = config.kubernetes.resources;
  priority = resources.priority;

  functions = (import ./modules/functions.nix { inherit pkgs; });
in
{
  imports = with integration-modules.modules; [
    kubernetes
  ];

  config = {
    kubernetes.resources.list = 
      with kubenix.modules;
      {
        "${priority.mid  "knative"}"     = [ knative ];
        "${priority.low  "monitoring"}"  = [ weavescope knative-monitoring ];
        "${priority.low  "gitops"}"      = [ argocd ];
        "${priority.low  "ci"}"          = [ brigade ];
        "${priority.skip "secrets"}"     = [ secrets ];
      } // functions;
  };
}