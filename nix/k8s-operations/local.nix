{ 
  pkgs, 
  lib, 
  project-config, 
  kubenix,
  log,
  node-development-tools
}:
let
  projectName = project-config.project.name;

  append-local-docker-registry-to-kind-nodes = pkgs.callPackage ./patch/kind.nix {};
  # INFO to filter out grep from ps
  getGrepPhrase = phrase:
    let
      phraseLength = builtins.stringLength phrase;
      grepPhrase = "[${builtins.substring 0 1 phrase}]";
      grepPhraseRest = builtins.substring 1 phraseLength phrase;
    in
      "${grepPhrase}${grepPhraseRest}";

  namespace = project-config.kubernetes.namespace;
  local-infra-ns = namespace.infra;
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
    ${log.message "Deleting cluster"}
    ${pkgs.minikube}/bin/minikube -p ${projectName} delete
  '';

  # brew install docker-machine-driver-hyperkit - check if there is a nixpkgs for that
  create-local-cluster = pkgs.writeScript "create-local-cluster" ''
    ${log.message "Creating cluster"}
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
    ${log.message "Checking existence of cluster ..."}
    isRunning=$(${check-if-already-started})
    if [ $isRunning = "0" ]; then
      echo "Running minikube"
      ${create-local-cluster}
    fi 
  '';

  get-port = {
    service,
    type ? "nodePort",
    index ? 0,
    port ? "",
    namespace
  }: pkgs.writeScript "get-port" ''
    ${pkgs.kubectl}/bin/kubectl get svc ${service} \
      --namespace ${namespace} \
      --output 'jsonpath={.spec.ports[${if port != "" then "?(@.port==${port})" else toString index}].${type}}'
  '';

  port-forward = {
    from,
    to,
    namespace,
    resourceType ? "service",
    service
  }: 
  pkgs.writeScript "port-forward-${namespace}-${service}" ''
    ${log.message "Forwarding ports $(${from}):$(${to}) for ${service}"}

    ps | grep "${getGrepPhrase service}" \
      || ${pkgs.kubectl}/bin/kubectl \
          port-forward ${resourceType}/${service} \
          --namespace ${namespace} \
          $(${toString to}):$(${toString from}) > /dev/null &
  '';

  # kubectl wait pod --for condition=ready --all -n brigade
  wait-for = {
    service,
    namespace,
    selector ? "",
    condition ? "condition=Ready",
    resource ? "pod",
    timeout ? 300,
  }:
    pkgs.writeScript "wait-for-${namespace}-${service}" ''
      ${log.message "Waiting for ${namespace}/${service}"}

      ${pkgs.kubectl}/bin/kubectl wait \
        --namespace ${namespace} \
        --for=${condition} ${resource} \
        ${if selector != "" then "--selector '${selector}'" else ""} \
        --timeout=${toString timeout}s
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
    ${log.message "Exposing localtunnel for brigade on port $(${brigade-ports.to})"}
    ${localtunnel} --port $(${brigade-ports.to}) --subdomain "${projectName}"
  '';

    # export BRIGADE_PROJECT=${env-config.brigade.project-name}
  setup-env-vars = pkgs.writeScriptBin "setup-env-vars" ''
    export BRIGADE_NAMESPACE=${brigade-service.namespace}
    eval $(${pkgs.minikube}/bin/minikube docker-env -p future-is-comming)
  '';

  skaffold-build = pkgs.writeScriptBin "skaffold-build" ''
    #!/bin/bash
    DIR=$(pwd)/result
    BUILDER="-f ./nix/development.nix"
    HASH="--argstr hash $IMAGES"

    ${pkgs.nix}/bin/nix build $BUILDER docker $HASH --out-link $DIR/docker-image
    ${pkgs.docker}/bin/docker load -i $DIR/docker-image

    ${pkgs.nix}/bin/nix build $BUILDER yaml $HASH --out-link $DIR/k8s-resource.yaml
  '';
}
