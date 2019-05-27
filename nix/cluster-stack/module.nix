{config, env-config, pkgs, kubenix, callPackage, ...}: 
let
  charts = callPackage ./charts.nix {};
  namespace = env-config.kubernetes.namespace.infra;
in
{
  imports = with kubenix.modules; [ helm k8s ];

  kubernetes.api.namespaces."${namespace}"= {};
  kubernetes.api.namespaces."istio-system"= {};

  kubernetes.helm.instances.brigade = {
    namespace = "${namespace}";
    chart = charts.brigade;
    # values = {
    # };
  };

  # INFO json cannot be applied here as it is handled via helm module
  kubernetes.helm.instances.brigade-bitbucket-gateway = {
    namespace = "${namespace}";
    chart = charts.brigade-bitbucket;
    values = {
    };
  };
}