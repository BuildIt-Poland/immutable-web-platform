{
  fresh ? false,
  brigadeSharedSecret ? "", # take from bitbucket -> webhooks X-Hook-UUID
  updateResources ? false, # kubernetes resource,
  autoExposePorts ? false,
  uploadDockerImages ? false,
  region ? null,
  config ? "",
  # TODO --arg config '{brigade.enable = true}'
  ...
}:
let
  pkgs = (import ./nix {
    inherit 
      brigadeSharedSecret 
      region;
  }).pkgs;

  # TODO make it better at least concatString

  applyResources = updateResources || fresh;

  mkConfig = {config, ...}: {
    config = {
      environment = "local";

      docker = {
        enable-registry = true;
        upload-images = ["functions" "cluster"];
      };

      brigade = {
        enable = true;
        secret-key = brigadeSharedSecret;
      };

      kubernetes = {
        resources.apply = updateResources;
        cluster.fresh-instance = fresh;
      };
    };
  };

  moduleConfig = (pkgs.modules.bootstrap mkConfig).config;

  shellHook = moduleConfig.shellHook;
  packages = moduleConfig.packages;
  warnings = moduleConfig.warnings;
  errors = moduleConfig.errors;
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
    hey

    # secrets
    sops

    # cluster scripts
    k8s-local.expose-istio-ingress
    # k8s-local.add-knative-label-to-istio
    # waits
    k8s-local.wait-for-istio-ingress
    k8s-local.wait-for-brigade-ingress

    # ingress & tunnels
    k8s-local.expose-istio-ingress
    k8s-local.expose-brigade-gateway
    k8s-local.expose-grafana
    k8s-local.expose-weave-scope

    # exports
    k8s-local.export-kubeconfig
    k8s-local.export-ports

    # helm
    k8s-cluster-operations.push-docker-images-to-local-cluster
  ] ++ moduleConfig.packages;

  PROJECT_NAME = env-config.projectName;

  # known issue: when starting clean cluster expose-brigade is run to early

  # TODO bootstrap can be easly faster -> check rbac and roles only when running new cluster
  shellHook= ''
    ${toString shellHook}

    ${lib.concatMapStrings log.warn warnings}
    ${lib.concatMapStrings log.error errors}

    ${log.message "Hey sailor!"}
    ${log.info "If you need any help, run 'get-help'"}

    ${env-config.info.printWarnings}

    ${if fresh 
         then "delete-local-cluster" else ""}

    create-local-cluster-if-not-exists
    source export-kubeconfig

    ${if applyResources
        then ''
          apply-cluster-stack
          wait-for-docker-registry
        '' else ""}

    ${if uploadDockerImages 
      then "push-docker-images-to-local-cluster" else ""}

    ${if applyResources
      then ''
        apply-functions-to-cluster

        source export-ports

        wait-for-istio-ingress
        expose-istio-ingress
      '' else ""
    }

    get-help
  '';
  # add-knative-label-to-istio
  # wait-for-brigade-ingress
  # expose-brigade-gateway
}