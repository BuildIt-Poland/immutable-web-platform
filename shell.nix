{
  kubernetes ? null,
  brigade ? null,
  docker ? null,
  aws ? null
}@inputs:
let
  defaults = with pkgs; (lib.recursiveUpdate {
    kubernetes = { clean = false; update = false; save = true; };
    docker = { upload = true; hash = ""; };
    brigade = { secret = ""; };
    aws = { region = ""; };
  } inputs);

  pkgs = (import ./nix {
    inputs = defaults;
    project-config = config;
  }).pkgs;

  config = (pkgs.shell-modules.eval {
    modules = [./nix/envs/local-env.nix];
    args = {
      inherit pkgs;
      inputs = defaults;
    };
  }).config;
in
with pkgs;
mkShell {
  buildInputs = [ ] ++ config.packages;

  PROJECT_NAME = config.project.name;

  shellHook= ''
    ${toString config.shellHook}
  '';
    # ${lib.concatMapStrings "\n" config.help}
  #   # js
  #   nodejs
  #   yarn2nix.yarn
  #   argocd

  #   # tools
  #   docker
  #   knctl
  #   brigade
  #   brigadeterm
  #   kubectl-repl
  #   node-development-tools
  #   kubernetes-helm
  #   hey
  #   istioctl
  #   skaffold
  #   minikube
  #   # bazel

  #   # secrets
  #   sops

  #   # waits
  #   # k8s-local.wait-for-brigade-ingress

  #   # ingress & tunnels
  #   # k8s-local.expose-istio-ingress
  #   k8s-local.expose-brigade-gateway

  #   # exports
  #   k8s-local.setup-env-vars
  #   k8s-local.minikube-wrapper
  #   k8s-local.skaffold-build
  #   # k8s-local.export-ports

  #   # helm
  #   k8s-cluster-operations.push-docker-images-to-local-cluster
  #   k8s-cluster-operations.apply-cluster-crd
  # ] ++ moduleConfig.packages;

  # PROJECT_NAME = env-config.projectName;

  # # known issue: when starting clean cluster expose-brigade is run to early

  # # TODO bootstrap can be easly faster -> check rbac and roles only when running new cluster
  # shellHook= ''
  #   ${toString shellHook}

  #   ${lib.concatMapStrings log.warn warnings}
  #   ${lib.concatMapStrings log.error errors}

  #   ${log.message "Hey sailor!"}
  #   ${log.info "If you need any help, run 'get-help'"}

  #   ${env-config.info.printWarnings}

  #   ${if fresh 
  #        then "delete-local-cluster" else ""}

  #   create-local-cluster-if-not-exists
  #   source setup-env-vars

  #   ${if fresh 
  #     then "apply-cluster-crd" else ""}

  #   ${if applyResources
  #       then ''
  #         apply-cluster-stack
  #       '' else ""}

  #   ${if uploadDockerImages 
  #     then "push-docker-images-to-local-cluster" else ""}

  #   ${if applyResources
  #     then ''
  #       apply-functions-to-cluster
  #     '' else ""
  #   }

  #   get-help
  # '';
    # add-knative-label-to-istio
  # wait-for-istio-ingress
  # expose-istio-ingress
  # wait-for-brigade-ingress
  # expose-brigade-gateway
}