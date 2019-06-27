{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  writeScript,
  writeScriptBin,
  charts,
  cluster,
  log,
  kubenix,
  lib
}:
let
  k8s-resources = callPackage ./k8s-resources.nix {};
in
with kubenix.lib;
rec {

  apply-resources = resources: writeScript "apply-resources" ''
    cat ${resources} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  wait-for = resource: condition: writeScript "wait-for-condition" ''
    ${pkgs.kubectl}/bin/kubectl wait ${resource} --for condition=${condition} --all --timeout=300s
  '';

  # INFO why waits -> https://github.com/knative/serving/issues/2195
  apply-istio-crd = writeScript "apply-istio-crd" ''
    ${apply-resources charts.istio-init-yaml}
    ${wait-for "job" "complete"}
    ${wait-for "crd" "established"}
  '';

  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    ${log.important "Applying functions helm charts"}
    ${apply-resources cluster.k8s-functions-resources}
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    ${log.important "Applying cluster helm charts"}

    ${apply-istio-crd}
    ${apply-resources cluster.k8s-cluster-resources}
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
        ${docker.copyDockerImages { 
          images = docker-images; 
          dest = env-config.docker.destination;
        }}/bin/copy-docker-images
      '') cluster.images);
}