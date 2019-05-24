{fresh ? false}@args:
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

    # kind
    pkgs.kind
    pkgs.docker
    pkgs.k8s-local.delete-local-cluster
    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.k8s-local.export-kubeconfig

    # helm
    pkgs.cluster-stack.apply-cluster-stack
    pkgs.cluster-stack.apply-functions-to-cluster
    pkgs.cluster-stack.push-docker-images-to-local-cluster
  ];

  PROJECT_NAME = pkgs.env-config.projectName;
  INGRESSGATEWAY = "istio-ingressgateway";

  shellHook= ''
    echo "Hey sailor!"

    ${if fresh then "delete-local-cluster" else ""}
    create-local-cluster-if-not-exists
    source export-kubeconfig

    push-docker-images-to-local-cluster
    apply-cluster-stack
    apply-functions-to-cluster
  '';
}