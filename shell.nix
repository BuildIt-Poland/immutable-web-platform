{fresh ? false, use-docker ? true}@args:
let
  pkgs = (import ./nix ({} // args)).pkgs;
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
    pkgs.functions.scripts.push-to-local-registry

    # kind
    kind
    pkgs.docker
    pkgs.k8s-local.delete-local-cluster
    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.k8s-local.export-kubeconfig

    # helm
    pkgs.cluster-stack.init
  ];

  PROJECT_NAME = pkgs.env-config.projectName;

  shellHook= ''
    echo "Hey sailor!"

    ${if fresh then "delete-local-cluster" else ""}
    create-local-cluster-if-not-exists
    source export-kubeconfig

    apply-cluster-stack
  '';
}