{ 
  pkgs, 
  lib, 
  project-config, 
  kubenix,
  node-development-tools,
  helpers
}:
with helpers;
let
  projectName = project-config.project.name;

  namespace = project-config.kubernetes.namespace;
  brigade-ns = namespace.brigade;
  istio-ns = namespace.istio;

  # TODO should be in config
  brigade-service = {
    service = "brigade-bitbucket-gateway-brigade-bitbucket-gateway"; # INFO chart is so so and does not hanle name well ... investigate
    namespace = brigade-ns;
  };

  istio-service = {
    service = "istio-ingressgateway";
    namespace = istio-ns;
  };

  registry-service = {
    service = "docker-registry";
    namespace = local-infra-ns;
  };

  localtunnel = "${node-development-tools}/bin/lt";
in
rec {
  delete-local-cluster = pkgs.writeScriptBin "delete-local-cluster" ''
    ${lib.log.message "Deleting cluster"}
    ${pkgs.minikube}/bin/minikube -p ${projectName} delete
  '';

  # brew install docker-machine-driver-hyperkit - check if there is a nixpkgs for that
  create-local-cluster = pkgs.writeScript "create-local-cluster" ''
    ${lib.log.message "Creating cluster"}
    minikube start -p ${projectName} \
      --cpus 6 \
      --memory 16400 \
      --kubernetes-version=v1.14.2 \
      --vm-driver=hyperkit \
      --bootstrapper=kubeadm \
      --insecure-registry "10.0.0.0/24" \
      --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"
  '';

  check-if-already-started = pkgs.writeScript "check-if-minikube-started" ''
    echo $(${pkgs.minikube}/bin/minikube status -p ${projectName} --format {{.Kubelet}} | wc -c)
  '';

  create-local-cluster-if-not-exists = pkgs.writeScriptBin "create-local-cluster-if-not-exists" ''
    ${lib.log.message "Checking existence of cluster ..."}
    isRunning=$(${check-if-already-started})
    if [ $isRunning = "0" ]; then
      echo "Running minikube"
      ${create-local-cluster}
    fi 
  '';

  brigade-ports = {
    from = get-port ({ type = "port"; } // brigade-service);
    to = get-port ({ type = "nodePort"; } // brigade-service);
  };

  expose-brigade-gateway = pkgs.writeScriptBin "expose-brigade-gateway" ''
    ${port-forward (brigade-service // brigade-ports)}
  '';

  minikube-wrapper = pkgs.writeScriptBin "mk" ''
    ${pkgs.minikube}/bin/minikube $* -p ${projectName}
  '';

  # helpful flag ... --print-requests 
  create-localtunnel-for-brigade = pkgs.writeScriptBin "create-localtunnel-for-brigade" ''
    ${lib.log.message "Exposing localtunnel for brigade on port $(${brigade-ports.to})"}
    ${localtunnel} --port $(${brigade-ports.to}) --subdomain "${projectName}"
  '';

  # export BRIGADE_PROJECT=${env-config.brigade.project-name}
  # FIXME this is too late
  setup-env-vars = pkgs.writeScriptBin "setup-env-vars" ''
    ${lib.log.message "Exporting env vars and evaluating minikube docker-env"}
    eval $(${pkgs.minikube}/bin/minikube docker-env -p ${projectName})
  '';

  skaffold-build = pkgs.writeScriptBin "skaffold-build" ''
    #!/bin/bash
    DIR=$(pwd)/result
    BUILDER="-f ./nix/development.nix"
    HASH="--argstr tag $IMAGES"

    ${pkgs.nix}/bin/nix build $BUILDER docker $HASH --out-link $DIR/docker-image
    ${pkgs.docker}/bin/docker load -i $DIR/docker-image

    ${pkgs.nix}/bin/nix build $BUILDER yaml $HASH --out-link $DIR/k8s-resource.yaml
  '';
}
