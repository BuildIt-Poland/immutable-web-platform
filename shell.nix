{
  fresh ? false,
  updateResources ? false, # kubernetes resource,
  exposePorts ? false
}@args:
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

    # tools
    pkgs.kind
    pkgs.docker
    pkgs.knctl
    pkgs.brigade
    pkgs.node-development-tools

    # cluster scripts
    pkgs.k8s-local.delete-local-cluster
    pkgs.k8s-local.create-local-cluster-if-not-exists
    pkgs.k8s-local.export-kubeconfig
    pkgs.k8s-local.expose-istio-ingress
    pkgs.k8s-local.add-knative-label-to-istio

    # waits
    pkgs.k8s-local.wait-for-istio-ingress
    pkgs.k8s-local.wait-for-brigade-ingress

    # ingress & tunnels
    pkgs.k8s-local.expose-istio-ingress
    pkgs.k8s-local.expose-brigade-gateway
    pkgs.k8s-local.create-localtunnel-for-brigade

    # overridings
    pkgs.k8s-local.curl-with-resolve

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

    wait-for-istio-ingress
    add-knative-label-to-istio
    expose-istio-ingress

    wait-for-brigade-ingress
    expose-brigade-gateway

    export PATH="$PATH:${pkgs.node-development-tools}/bin"
  '';
}