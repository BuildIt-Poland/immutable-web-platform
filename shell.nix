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
    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.kind
  ];

  shellHook= ''
    echo "Hey sailor!"

    create-local-cluster-if-not-exists

    export PROJECT_NAME="${pkgs.env-config.projectName}"
    export KUBECONFIG=$(${pkgs.kind}/bin/kind get kubeconfig-path --name=$PROJECT_NAME)
  '';
}