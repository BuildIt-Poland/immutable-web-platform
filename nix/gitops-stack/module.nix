{
  config, 
  env-config, 
  pkgs, 
  kubenix, 
  charts,
  callPackage, 
  ...
}: 
let
  namespace = env-config.kubernetes.namespace;
  argo-ns = namespace.argo;
in
{
  imports = with kubenix.modules; [ helm k8s docker istio ];
}