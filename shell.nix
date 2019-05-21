{fresh ? true}:
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
    pkgs.docker
    pkgs.k8s-local.delete-local-cluster
    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.k8s-local.export-kubeconfig

    # helm
    # pkgs.kubernetes-helm
    pkgs.helm-scripts.init
    pkgs.helm-scripts.helm-local
    pkgs.helm-scripts.add-repositories
  ];

  PROJECT_NAME = pkgs.env-config.projectName;

  shellHook= ''
    echo "Hey sailor!"

    ${if fresh then "delete-local-cluster" else ""}
    create-local-cluster-if-not-exists
    source export-kubeconfig

    helm-init
    add-helm-repositories
  '';
}