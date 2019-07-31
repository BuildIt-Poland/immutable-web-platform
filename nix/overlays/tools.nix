{sources}:
self: super:
let
  rootFolder = ../../.;
  nodePackages = "${rootFolder}/packages";
in
rec {
  # Terraform
  terraform-with-plugins = super.callPackage ../terraform {};

  # Helpers
  find-files-in-folder = (super.callPackage ../helpers/find-files-in-folder.nix {}) rootFolder;
  log = super.callPackage ../helpers/log.nix {};

  lib = super.lib.recursiveUpdate super.lib {
    makeDefault = import ../helpers/make-default.nix;
    parseINI = super.callPackage ../helpers/parse-ini.nix {};
  };

  # Brigade
  brigade = super.callPackage ../tools/brigade.nix {};
  brigadeterm = super.callPackage ../tools/brigadeterm.nix {};

  # K8S
  knctl = super.callPackage ../tools/knctl.nix {}; # knative
  kubectl-repl = super.callPackage ../tools/kubectl-repl.nix {}; 
  hey = super.callPackage ../tools/hey.nix {}; 
  istioctl = super.callPackage ../tools/istioctl.nix {}; 

  # docker
  dgoss = super.callPackage ../tools/dgoss.nix {}; 

  # NodeJS packages
  node-development-tools = super.callPackage "${nodePackages}/development-tools/nix" {};
  # brigade-extension = super.callPackage "${nodePackages}/brigade-extension/nix" {};
  remote-state = super.callPackage "${nodePackages}/remote-state/nix" {};

  # gitops
  # THIS is correct way however need some final touches to make this right
  # argocd = super.callPackage ./gitops/argocd {};
  argocd = super.callPackage ../tools/argocd.nix {};

  yarn2nix = super.callPackage sources.yarn2nix {};

  # INFO I need to have hibernate feature for aws
  nixops = (import "${sources.nixops.outPath}/release.nix" {}).build.${super.system};
}