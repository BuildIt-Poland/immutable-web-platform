{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  writeScript,
  writeScriptBin,
  cluster,
  log,
  kubenix,
  lib
}:
let
  k8s-resources = callPackage ./k8s-resources.nix {};
in
rec {
  inject-sidecar-to = namespace: writeScript "inside-sidecar-to" ''
    ${pkgs.kubectl}/bin/kubectl label namespace ${namespace} istio-injection=enabled
  '';

  apply-knative-with-istio = writeScript "apply-knative-with-istio" ''
    ${pkgs.kubectl}/bin/kubectl apply -f ${k8s-resources .istio-crds}/istio-crds.yaml
    ${pkgs.kubectl}/bin/kubectl apply -f ${k8s-resources .istio}/istio-node-port.yaml
    ${inject-sidecar-to env-config.kubernetes.namespace.functions}

    ${pkgs.kubectl}/bin/kubectl apply -f ${k8s-resources .knative-serving}/knative-serving.yaml
  '';

  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    cat ${cluster.k8s-resources} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    ${log.important "Applying helm charts"}
    ${apply-knative-with-istio}
  '';

  push-docker-images-to-local-cluster = writeScriptBin "push-docker-images-to-local-cluster"
    (lib.concatMapStrings 
      (docker-image: ''
        ${log.important "Pushing docker image to local cluster: ${docker-image}"}
        ${pkgs.kind}/bin/kind load image-archive --name ${env-config.projectName} ${docker-image}
      '') cluster.images);

  push-to-docker-registry = writeScriptBin "push-to-docker-registry"
    (lib.concatMapStrings 
      (docker-images: ''
        ${kubenix.lib.docker.copyDockerImages { 
          images = docker-images; 
          dest = env-config.docker.destination;
        }}/bin/copy-docker-images
      '') cluster.images);
}