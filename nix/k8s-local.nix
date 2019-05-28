{ pkgs, lib, env-config, kubenix }:
let
  # INFO to filter out grep from ps
  getGrepPhrase = phrase:
    let
      phraseLength = builtins.stringLength phrase;
      grepPhrase = "[${builtins.substring 0 1 phrase}]";
      grepPhraseRest = builtins.substring 1 phraseLength phrase;
    in
      "${grepPhrase}${grepPhraseRest}";

  local-infra-ns = env-config.kubernetes.namespace.infra;

  brigade-service = {
    service = "brigade-bitbucket-gateway-brigade-bitbucket-gateway"; # INFO chart is so so and does not hanle name well ... investigate
    namespace = local-infra-ns;
  };

  istio-service = {
    service = "istio-ingressgateway";
    namespace = "istio-system";
  };
in
rec {
  delete-local-cluster = pkgs.writeScriptBin "delete-local-cluster" ''
    echo "Deleting cluster"
    ${pkgs.kind}/bin/kind delete cluster --name ${env-config.projectName} || true
  '';

  cluster-config = {
    kind = "Cluster";
    apiVersion = "kind.sigs.k8s.io/v1alpha3";
    nodes = [
      { 
        role = "control-plane"; 
        extraMounts = [{
          containerPath = "/kind-source";
          hostPath = toString ./.;
          readOnly = true;
        }];
      }
      { role = "worker"; }
      { role = "worker"; }
    ];
  };

  cluster-config-yaml = kubenix.lib.toYAML cluster-config;

  create-local-cluster = pkgs.writeScript "create-local-cluster" ''
    echo "Creating cluster"
    ${pkgs.kind}/bin/kind create cluster --name ${env-config.projectName} --config ${cluster-config-yaml}
  '';

  create-local-cluster-if-not-exists = pkgs.writeScriptBin "create-local-cluster-if-not-exists" ''
    echo "Checking existence of cluster ..."
    ${pkgs.kind}/bin/kind get clusters | grep ${env-config.projectName} || ${create-local-cluster}
  '';

  getPortScript = "$(kubectl get svc $INGRESSGATEWAY --namespace istio-system --output 'jsonpath={.spec.ports[?(@.port==80)].nodePort}')";

  get-port = {
    service,
    type ? "port", # nodePort or port # TODO this should be an option
    index ? 0,
    namespace
  }: pkgs.writeScript "get-port" ''
    ${pkgs.kubectl}/bin/kubectl get svc ${service} --namespace ${namespace} --output 'jsonpath={.spec.ports[${toString index}].${type}}';
  '';

  port-forward = {
    from,
    to,
    namespace,
    resourceType ? "service",
    service
  }: 
  pkgs.writeScript "port-forward-${namespace}-${service}" ''
    echo "Forwarding ports $(${from}):$(${to}) for ${service}"

    ps | grep "${getGrepPhrase service}" \
      || ${pkgs.kubectl}/bin/kubectl \
          --namespace ${namespace} \
          port-forward ${resourceType}/${service} \
          $(${toString to}):$(${toString from}) > /dev/null &
  '';

  wait-for = {
    service,
    namespace,
    selector,
    condition ? "condition=Ready",
    resource ? "pod",
    timeout ? 300,
  }:
    pkgs.writeScript "wait-for-${namespace}-${service}" ''
      echo "Waiting for ${namespace}/${service}"
      ${pkgs.kubectl}/bin/kubectl wait \
        --namespace ${namespace} \
        --for=${condition} ${resource} \
        --selector '${selector}' --timeout=${toString timeout}s
  '';

  brigade-ports = {
    from = get-port ({ type = "port"; } // brigade-service);
    to = get-port ({ type = "nodePort"; } // brigade-service);
  };

  istio-ports = {
    from = get-port ({ type = "port"; } // istio-service);
    to = get-port ({ type = "nodePort"; } // istio-service);
  };

  wait-for-istio-ingress = pkgs.writeScriptBin "wait-for-istio-ingress" ''
    ${wait-for ({selector= "app=${istio-service.service}";} // istio-service)}
  '';

  wait-for-brigade-ingress = pkgs.writeScriptBin "wait-for-brigade-ingress" ''
    ${wait-for ({selector= "app=${brigade-service.service}";} // brigade-service)}
  '';

  # https://github.com/kubernetes-sigs/kind/issues/99
  expose-istio-ingress = pkgs.writeScriptBin "expose-istio-ingress" ''
    ${port-forward (istio-service // istio-ports)}
  '';

  expose-brigade-gateway = pkgs.writeScriptBin "expose-brigade-gateway" ''
    ${port-forward (brigade-service // brigade-ports)}
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
    ${pkgs.kubectl}/bin/kubectl patch service istio-ingressgateway --namespace istio-system -p '${builtins.toJSON knative-label-patch}'
  '';

  export-kubeconfig = pkgs.writeScriptBin "export-kubeconfig" ''
    export KUBECONFIG=$(${pkgs.kind}/bin/kind get kubeconfig-path --name=${env-config.projectName})
    export BRIGADE_NAMESPACE=${env-config.kubernetes.namespace.infra}
  '';

  deploy-to-kind = {config, image}: 
    pkgs.writeScriptBin "deploy-to-kind" ''
      echo "Loading the ${pkgs.docker}/bin/docker image inside the kind docker container ..."

      kind load image-archive ${image}
      echo "Applying the configuration ..."

      cat ${config} | ${pkgs.jq}/bin/jq "."
      cat ${config} | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';

  # about makeWrapper https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh#L13
  # about resolve https://curl.haxx.se/docs/manpage.html
  curl-with-resolve = pkgs.stdenv.mkDerivation rec {
    name = "curl-with-localhost";
    version = "0.0.1";
    buildInputs = [pkgs.makeWrapper pkgs.curl];
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.curl}/bin/curl $out/bin/curl \
        --add-flags "--resolve ${env-config.projectName}-control-plane:\$KUBE_NODE_PORT:127.0.0.1"
    '';
  };
}
