{ }:
let
  pkgs = (import ./nix {}).pkgs;
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  buildInputs = [
    nodejs
    pkgs.yarn2nix.yarn
    pkgs.functions.scripts.build-and-push
    pkgs.kind

    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.k8s-local.export-kubeconfig
  ];

  PROJECT_NAME = pkgs.env-config.projectName;

  shellHook= ''
    echo "Hey sailor!"

    create-local-cluster-if-not-exists

    source export-kubeconfig
  '';
}