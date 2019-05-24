{ pkgs, env-config }:
rec {
  delete-local-cluster = pkgs.writeScriptBin "delete-local-cluster" ''
    echo "Deleting cluster"
    ${pkgs.kind}/bin/kind delete cluster --name ${env-config.projectName} || true
  '';

  create-local-cluster = pkgs.writeScript "create-local-cluster" ''
    echo "Creating cluster"
    ${pkgs.kind}/bin/kind create cluster --name ${env-config.projectName}
  '';

  create-local-cluster-if-not-exists = pkgs.writeScriptBin "create-local-cluster-if-not-exists" ''
    echo "Checking existence of cluster ..."
    ${pkgs.kind}/bin/kind get clusters | grep ${env-config.projectName} || ${create-local-cluster}
  '';

  export-kubeconfig = pkgs.writeScriptBin "export-kubeconfig" ''
    export KUBECONFIG=$(${pkgs.kind}/bin/kind get kubeconfig-path --name=${env-config.projectName})

    export CLUSTER_NODE_PORT=$(kubectl get svc $INGRESSGATEWAY --namespace istio-system  --output 'jsonpath={.spec.ports[?(@.port==80)].nodePort}')
    export CLUSTER_HOST=$(kubectl get node --output 'jsonpath={.items[0].status.addresses[0].address}')
    export CLUSTER_IP_ADDRESS=$CLUSTER_HOST:$CLUSTER_NODE_PORT
  '';

  deploy-to-kind = {config, image}: 
    pkgs.writeScriptBin "deploy-to-kind" ''
      echo "Loading the ${pkgs.docker}/bin/docker image inside the kind docker container ..."

      kind load image-archive ${image}
      echo "Applying the configuration ..."

      cat ${config} | ${pkgs.jq}/bin/jq "."
      cat ${config} | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';
}
