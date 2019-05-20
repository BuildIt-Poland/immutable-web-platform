{ }:
let
  pkgs = (import ./nix {}).pkgs;
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  buildInputs = [
    # js
    nodejs
    pkgs.yarn2nix.yarn

    # docker
    pkgs.functions.scripts.build-and-push

    # kind
    pkgs.kind
    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.k8s-local.export-kubeconfig

    # helm
    pkgs.kubernetes-helm
    pkgs.helm-scripts.init
  ];

  PROJECT_NAME = pkgs.env-config.projectName;

  shellHook= ''
    echo "Hey sailor!"

    create-local-cluster-if-not-exists
    source export-kubeconfig

    helm-init
  '';
}