{
  fresh ? false,
  brigadeSharedSecret ? "", # take from bitbucket -> webhooks X-Hook-UUID
  updateResources ? false, # kubernetes resource,
  autoExposePorts ? false
}@args:
let
  pkgs = (import ./nix {
    inherit brigadeSharedSecret;
  }).pkgs;
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  buildInputs = [
    # js
    nodejs
    yarn2nix.yarn

    # tools
    kind
    docker
    knctl
    brigade
    brigadeterm
    node-development-tools

    # secrets
    sops

    # cluster scripts
    k8s-local.delete-local-cluster
    k8s-local.create-local-cluster-if-not-exists
    k8s-local.expose-istio-ingress
    k8s-local.add-knative-label-to-istio

    # waits
    k8s-local.wait-for-istio-ingress
    k8s-local.wait-for-brigade-ingress

    # ingress & tunnels
    k8s-local.expose-istio-ingress
    k8s-local.expose-brigade-gateway
    k8s-local.create-localtunnel-for-brigade

    # exports
    k8s-local.export-kubeconfig
    k8s-local.export-ports

    # overridings
    k8s-local.curl-with-resolve

    # helm
    k8s-cluster-operations.apply-cluster-stack
    k8s-cluster-operations.apply-functions-to-cluster
    k8s-cluster-operations.push-docker-images-to-local-cluster
  ];

  PROJECT_NAME = env-config.projectName;

  # known issue: when starting clean cluster expose-brigade is run to early
  shellHook= ''
    ${log.message "Hey sailor!"}

    ${env-config.info.printWarnings}
    ${env-config.info.printInfos}

    ${if fresh then "delete-local-cluster" else ""}

    create-local-cluster-if-not-exists
    source export-kubeconfig

    push-docker-images-to-local-cluster
    apply-cluster-stack
    apply-functions-to-cluster

    source export-ports

    wait-for-istio-ingress
    add-knative-label-to-istio
    expose-istio-ingress

    wait-for-brigade-ingress
    expose-brigade-gateway
  '';
}