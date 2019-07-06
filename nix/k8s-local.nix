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
    ${pkgs.kind}/bin/kind delete cluster --name ${env-config.projectName} || true
  '';

  cluster-config = {
    kind = "Cluster";
    apiVersion = "kind.sigs.k8s.io/v1alpha3";
    nodes = [
      { 
        role = "control-plane"; 
        extraMounts = [{
          containerPath = "/project";
          hostPath = toString ./.;
          readOnly = true;
        }];
      }
      { role = "worker"; }
      { role = "worker"; }
    ];
  };

  cluster-config-yaml = kubenix.lib.toYAML cluster-config;

  wait-for-docker-registry = pkgs.writeScriptBin "wait-for-docker-registry" ''
    ${wait-for ({selector= "app=${registry-service.service}";} // registry-service)}
    ${port-forward (registry-service // registry-ports)}
  '';

  create-local-cluster = pkgs.writeScript "create-local-cluster" ''
    ${log.message "Creating cluster"}
    ${pkgs.kind}/bin/kind create cluster --name ${env-config.projectName} --config ${cluster-config-yaml}
  '';

  create-local-cluster-if-not-exists = pkgs.writeScriptBin "create-local-cluster-if-not-exists" ''
    ${log.message "Checking existence of cluster ..."}
    ${append-local-docker-registry-to-kind-nodes}/bin/append-local-docker-registry
    ${pkgs.kind}/bin/kind get clusters | grep ${env-config.projectName} || ${create-local-cluster}
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

  registry-ports = 
  let
    registry = env-config.docker.local-registry;
  in
  {
    from = "echo ${toString registry.clusterPort}"; # get-port ({ type = "port"; } // registry-service);
    to = "echo ${toString registry.exposedPort}"; # get-port ({ type = "nodePort"; } // registry-service);
  };

  brigade-ports = {
    from = get-port ({ type = "port"; } // brigade-service);
    to = get-port ({ type = "nodePort"; } // brigade-service);
  };

  istio-ports = {
    from = "echo '80'"; # so so but it expect a bash command
    to = get-port ({ type = "nodePort"; port = "80"; } // istio-service);
  };

  wait-for-istio-ingress = pkgs.writeScriptBin "wait-for-istio-ingress" ''
    ${wait-for ({selector= "app=${istio-service.service}";} // istio-service)}
  '';

  # ISSUE: first run -> wait for istio or namespace
  wait-for-brigade-ingress = pkgs.writeScriptBin "wait-for-brigade-ingress" ''
    ${wait-for ({selector= "app=${brigade-service.service}"; timeout = 800;} // brigade-service)}
  '';

  # https://github.com/kubernetes-sigs/kind/issues/99
  expose-istio-ingress = pkgs.writeScriptBin "expose-istio-ingress" ''
    ${port-forward (istio-service // istio-ports)}
  '';

  expose-brigade-gateway = pkgs.writeScriptBin "expose-brigade-gateway" ''
    ${port-forward (brigade-service // brigade-ports)}
  '';

  # TODO make this more robust
  expose-grafana = pkgs.writeScriptBin "expose-grafana" ''
    ${pkgs.kubectl}/bin/kubectl port-forward --namespace knative-monitoring \
      $(${pkgs.kubectl}/bin/kubectl get pods --namespace knative-monitoring \
      --selector=app=grafana --output=jsonpath="{.items..metadata.name}") \
      3001:3000
  '';

  expose-weave-scope = pkgs.writeScriptBin "expose-weave-scope" ''
    ${pkgs.kubectl}/bin/kubectl port-forward --namespace istio-system svc/weave-scope-app 3002:80
  '';

  # helpful flag ... --print-requests 
  create-localtunnel-for-brigade = pkgs.writeScriptBin "create-localtunnel-for-brigade" ''
    ${log.message "Exposing localtunnel for brigade on port $(${brigade-ports.to})"}
    ${localtunnel} --port $(${brigade-ports.to}) --subdomain "${env-config.projectName}"
  '';

  # INFO ideally it would be handled via kubenix - need to do some reasearch
  knative-label-patch = {
    metadata = {
      labels = {
        knative = "ingressgateway";
      };
    };
  };

  # https://github.com/cppforlife/knctl/blob/master/docs/cmd/knctl_ingress_list.md
  add-knative-label-to-istio = pkgs.writeScriptBin "add-knative-label-to-istio" ''
    ${pkgs.kubectl}/bin/kubectl patch service istio-ingressgateway --namespace ${istio-ns} -p '${builtins.toJSON knative-label-patch}'
  '';

  export-kubeconfig = pkgs.writeScriptBin "export-kubeconfig" ''
    export KUBECONFIG=$(${pkgs.kind}/bin/kind get kubeconfig-path --name=${env-config.projectName})
    export BRIGADE_NAMESPACE=${brigade-service.namespace}
    export BRIGADE_PROJECT=${env-config.brigade.project-name}
  '';

  export-ports = pkgs.writeScriptBin "export-ports" ''
    export KUBE_NODE_PORT=$(${istio-ports.to})
  '';

  deploy-to-kind = {config, image}: 
    pkgs.writeScriptBin "deploy-to-kind" ''
      ${log.message "Loading the ${pkgs.docker}/bin/docker image inside the kind docker container ..."}

      kind load image-archive ${image}

      ${log.important "Applying the configuration ..."}

      cat ${config} | ${pkgs.jq}/bin/jq "."
      cat ${config} | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';

  # about makeWrapper https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh#L13
  # about resolve https://curl.haxx.se/docs/manpage.html
  curl-with-resolve = pkgs.stdenv.mkDerivation rec {
    name = "curl-with-localhost";
    version = "0.0.3";
    buildInputs = [pkgs.makeWrapper pkgs.curl];
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.curl}/bin/curl $out/bin/curl \
        --add-flags "--resolve ${env-config.projectName}-control-plane:\$KUBE_NODE_PORT:127.0.0.1"
    '';
  };
}
