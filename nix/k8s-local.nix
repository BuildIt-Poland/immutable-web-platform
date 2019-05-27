{ pkgs, lib, env-config, kubenix }:
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

  # https://github.com/kubernetes-sigs/kind/issues/99
  expose-istio-ingress = pkgs.writeScriptBin "expose-istio-ingress" ''
    ps | grep "[i]stio-ingressgateway" \
      || ${pkgs.kubectl}/bin/kubectl --namespace istio-system port-forward service/istio-ingressgateway $KUBE_NODE_PORT:80 > /dev/null &
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

  wait-for-istio-ingress = pkgs.writeScriptBin "wait-for-istio-ingress" ''
    ${pkgs.kubectl}/bin/kubectl -n istio-system wait --for=condition=Ready pod --selector "app=istio-ingressgateway" --timeout=300s
  '';

  export-ports = pkgs.writeScriptBin "export-ports" ''
    export KUBE_NODE_PORT=${getPortScript}
    echo "exposing ingress port from istio-ingress $KUBE_NODE_PORT"
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
