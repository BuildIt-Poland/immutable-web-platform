{sources}:
self: super:
let
  nodePackages = ../../packages;
in
rec {
  # Terraform
  terraform-with-plugins = super.callPackage ./terraform {};
  hydra-cli = (super.callPackage sources.hydra-cli {}).hydra-cli;

  # Brigade
  brigade = super.callPackage ./brigade {};
  brigadeterm = super.callPackage ./brigadeterm {};

  # K8S
  kn = super.callPackage ./kn {};
  kube-prompt = super.callPackage ./kube-prompt {}; 
  hey = super.callPackage ./hey {}; 
  istioctl = super.callPackage ./istioctl {}; 

  # docker
  dgoss = super.callPackage ./dgoss {}; 

  # backups
  velero = super.callPackage ./velero {};
  restic = super.callPackage ./restic {};

  # NodeJS packages
  node-development-tools = super.callPackage "${nodePackages}/development-tools/nix" {};
  remote-state = super.callPackage "${nodePackages}/remote-state/nix" {};

  # gitops
  argocd = super.callPackage ./argocd {};

  conftest = super.callPackage ./conftest {};
  opa = super.callPackage ./opa {};
  popeye = super.callPackage ./popeye {};

  kubectl-krew = super.callPackage ./kubectl-krew {};
  kubectl-dig = super.callPackage ./kubectl-dig {};
  kubectl-debug = super.callPackage ./kubectl-debug {};

  yarn2nix = super.callPackage sources.yarn2nix {};

  # yarn2nix = super.callPackage (super.applyPatches {
  #   src = super.fetchFromGitHub {
  #     sha256 = sources.yarn2nix.sha256;
  #     repo = sources.yarn2nix.repo;
  #     owner = sources.yarn2nix.owner;
  #     rev = sources.yarn2nix.rev;
  #   };
  #   patches = [./yarn2nix.patch];
  # }) {};

  # INFO I need to have hibernate feature for aws
  nixops = (import "${sources.nixops.outPath}/release.nix" {}).build.${super.system};
} 