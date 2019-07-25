{ 
  pkgs, 
  lib, 
  env-config, 
  kubenix,
  log,
  node-development-tools
}:
let
  append-local-docker-registry-to-kind-nodes = pkgs.callPackage ./patch/kind.nix {};
  # INFO to filter out grep from ps
  getGrepPhrase = phrase:
    let
      phraseLength = builtins.stringLength phrase;
      grepPhrase = "[${builtins.substring 0 1 phrase}]";
      grepPhraseRest = builtins.substring 1 phraseLength phrase;
    in
      "${grepPhrase}${grepPhraseRest}";

  namespace = env-config.kubernetes.namespace;
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
    minikube -p ${env-config.projectName} delete
  '';
    # ${pkgs.kind}/bin/kind delete cluster --name ${env-config.projectName} || true

  cluster-config = {
    kind = "Cluster";
    apiVersion = "kind.sigs.k8s.io/v1alpha3";
    nodes = 
    let
      ports = [
        # monitoring
        # grafana
        {
          containerPort = 31300;
          hostPort = 31300;
        }
        # weavescope
        {
          containerPort = 31301;
          hostPort = 31301;
        }
        # zipkin
        {
          containerPort = 31302;
          hostPort = 31302;
        }
        # argocd 
        {
          containerPort = 31200;
          hostPort = 31200;
        }
        # TODO make the same with istio and remove custom curl! super awesome!
        # and then we can skip port-forwarding!
        # port-forward service/docker-registry --namespace local-infra 32001:5000
        # port-forward service/istio-ingressgateway --namespace istio-system 31380:80
      ];
    in
    [
      { 
        role = "control-plane"; 
        extraMounts = [{
          containerPath = "/project";
          hostPath = toString ./.;
          readOnly = true;
        }];
        extraPortMappings = ports;
      }
      { role = "worker"; }
      { role = "worker"; }
    ];
  };

  cluster-config-yaml = kubenix.lib.toYAML cluster-config;

  # hyperkit is suggested by minikube
  # brew install docker-machine-driver-hyperkit - check if there is a nixpkgs for that
  create-local-cluster = pkgs.writeScript "create-local-cluster" ''
    ${log.message "Creating cluster"}
    minikube start -p ${env-config.projectName} \
      --cpus 6 \
      --memory 16400 \
      --kubernetes-version=v1.14.2 \
      --vm-driver=hyperkit \
      --bootstrapper=kubeadm \
      --insecure-registry "10.0.0.0/24" \
      --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"
  '';
  # ${pkgs.kind}/bin/kind create cluster --name ${env-config.projectName} --config ${cluster-config-yaml}
  # ${append-local-docker-registry-to-kind-nodes}/bin/append-local-docker-registry

  check-if-already-started = pkgs.writeScript "check-if-minikube-started" ''
    echo $(${pkgs.minikube}/bin/minikube status -p ${env-config.projectName} --format {{.Kubelet}} | wc -c)
  '';

  # ${pkgs.kind}/bin/kind get clusters | grep ${env-config.projectName} || ${create-local-cluster}
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

  # helpful flag ... --print-requests 
  create-localtunnel-for-brigade = pkgs.writeScriptBin "create-localtunnel-for-brigade" ''
    ${log.message "Exposing localtunnel for brigade on port $(${brigade-ports.to})"}
    ${localtunnel} --port $(${brigade-ports.to}) --subdomain "${env-config.projectName}"
  '';

  # INFO in case of minikube this is not necessary
  # export KUBECONFIG=$(${pkgs.kind}/bin/kind get kubeconfig-path --name=${env-config.projectName})
  setup-env-vars = pkgs.writeScriptBin "setup-env-vars" ''
    export BRIGADE_NAMESPACE=${brigade-service.namespace}
    export BRIGADE_PROJECT=${env-config.brigade.project-name}
    eval $(${pkgs.minikube}/bin/minikube docker-env -p future-is-comming)
  '';
}
