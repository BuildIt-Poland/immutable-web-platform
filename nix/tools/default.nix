{sources}:
self: super:
let
  nodePackages = ../../packages;
in
rec {
  # Terraform
  terraform-with-plugins = super.callPackage ../terraform {};

  lib = super.lib.recursiveUpdate super.lib (import ../helpers { callPackage = super.callPackage; });

  # Brigade
  brigade = super.callPackage ./brigade {};
  brigadeterm = super.callPackage ./brigadeterm {};

  # K8S
  knative = super.callPackage ./knative {};
  kube-prompt = super.callPackage ./kube-prompt {}; 
  hey = super.callPackage ./hey {}; 
  istioctl = super.callPackage ./istioctl {}; 

  # docker
  dgoss = super.callPackage ./dgoss {}; 
  kaniko-build = super.callPackage ./builder/kaniko.nix {};

  # backups
  velero = super.callPackage ./velero {};
  restic = super.callPackage ./restic {};

  # NodeJS packages
  node-development-tools = super.callPackage "${nodePackages}/development-tools/nix" {};
  remote-state = super.callPackage "${nodePackages}/remote-state/nix" {};

  # gitops
  argocd = super.callPackage ./argocd {};

  yarn2nix = super.callPackage sources.yarn2nix {};

  # INFO I need to have hibernate feature for aws
  nixops = (import "${sources.nixops.outPath}/release.nix" {}).build.${super.system};
}