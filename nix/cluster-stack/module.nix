{config, env-config, pkgs, kubenix, callPackage, ...}: 
let
  charts = callPackage ./charts.nix {};
  namespace = env-config.helm.namespace;
in
{
  imports = with kubenix.modules; [ helm ];

  kubernetes.api.namespaces."${namespace}"= {};

  kubernetes.helm.instances.brigade = {
    namespace = "${namespace}";
    chart = charts.brigade;
  };
}