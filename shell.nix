{
  fresh ? false,
  brigadeSharedSecret ? "", # take from bitbucket -> webhooks X-Hook-UUID
  updateResources ? false, # kubernetes resource,
  autoExposePorts ? false,
  uploadDockerImages ? false
}@args:
let
  pkgs = (import ./nix {
    inherit brigadeSharedSecret;
  }).pkgs;

  # TODO make it better at least concatString
  get-help = pkgs.writeScriptBin "get-help" ''
    echo "You've got in shell some extra spells under your hand ..."
    echo "-- Brigade integration --"
    echo "To expose brigade gateway for BitBucket events, run '${pkgs.k8s-local.expose-brigade-gateway.name}'"
    echo "To make gateway accessible from outside, run '${pkgs.k8s-local.create-localtunnel-for-brigade.name}'"
  '';
in
with pkgs;
mkShell {
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
    kubectl-repl
    node-development-tools
    kubernetes-helm

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

    # help
    get-help
  ];

  PROJECT_NAME = env-config.projectName;

  # known issue: when starting clean cluster expose-brigade is run to early
  
  shellHook= ''
    ${log.message "Hey sailor!"}
    ${log.info "If you need any help, run 'get-help'"}

    ${env-config.info.printWarnings}
    ${env-config.info.printInfos}

    ${if fresh 
         then "delete-local-cluster" else ""}

    create-local-cluster-if-not-exists
    source export-kubeconfig

    ${if uploadDockerImages 
         then "push-docker-images-to-local-cluster" else ""}

    apply-cluster-stack
    apply-functions-to-cluster

    source export-ports

    wait-for-istio-ingress
    add-knative-label-to-istio
    expose-istio-ingress

    get-help
  '';
  # wait-for-brigade-ingress
  # expose-brigade-gateway
}