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
with kubenix.lib;
rec {

  ## remove this two resources related to istio
  ## check if order is okey for knative - istio is defined in module knative applied after crd not istio
  apply-knative = writeScript "apply-knative" ''
    ${pkgs.kubectl}/bin/kubectl apply -f ${k8s-resources.knative-serving}
  '';

  apply-resources = resources: writeScript "apply-resources" ''
    cat ${resources} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  wait-for = resource: condition: writeScript "wait-for-condition" ''
    ${pkgs.kubectl}/bin/kubectl wait ${resource} --for condition=${condition} --all --timeout=300s
  '';

  # INFO why waits -> https://github.com/knative/serving/issues/2195
  apply-istio-crd = writeScript "apply-istio-crd" ''
    ${apply-resources cluster.charts.istio-init-yaml}
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
    ${apply-knative}
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