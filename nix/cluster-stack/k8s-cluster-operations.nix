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
    ${log.important "Applying resources ${resources}"}
    cat ${resources} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  # TODO create kubectl-helpers - DRY!
  wait-for = resource: condition: writeScript "wait-for-condition" ''
    ${pkgs.kubectl}/bin/kubectl wait ${resource} --for condition=${condition} --all --timeout=300s
  '';

  # TODO Save istio init and other crd as well
  save-resources = 
    let
      loc = env-config.resources.yaml.location;
    in
      writeScriptBin "save-resources" ''
        ${log.important "Saving yamls to: $PWD${loc}"}
        cat ${resources.yaml.crd} > $PWD${loc}/crd.yaml
        cat ${resources.yaml.cluster} > $PWD${loc}/cluster.yaml
        cat ${resources.yaml.functions} > $PWD${loc}/functions.yaml
      '';

  # INFO why waits -> https://github.com/knative/serving/issues/2195
  # TODO this should be in k8s-resources - too many places with charts and jsons
  # TODO there should be something global like init crd
    # ${apply-resources charts.istio-init-yaml}
  apply-cluster-crd = writeScriptBin "apply-cluster-crd" ''
    ${apply-resources resources.yaml.crd}
    ${wait-for "job" "complete"}
    ${wait-for "crd" "established"}
  '';

  resources = {
    yaml = {
      crd = k8s-resources.cluster-crd;
      cluster= cluster.k8s-cluster-resources;
      functions = cluster.k8s-functions-resources;
    };
  };

  # TODO enable flag - print resources
  # TODO https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml

  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    ${log.important "Applying functions helm charts"}
    ${apply-resources cluster.k8s-functions-resources}
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    ${log.important "Applying cluster helm charts"}
    ${apply-resources cluster.k8s-cluster-resources}
  '';

  push-docker-images-to-local-cluster = writeScriptBin "push-docker-images-to-local-cluster"
    (lib.concatMapStrings 
      (docker-image: ''
        ${log.important "Pushing docker image to local cluster: ${docker-image}, ${docker-image.imageName}:${docker-image.imageTag}"}
        ${pkgs.skopeo}/bin/skopeo \
          --insecure-policy \
          copy \
          docker-archive://${docker-image} \
          docker://localhost:${toString env-config.docker.local-registry.exposedPort}/${docker-image.imageName}:${docker-image.imageTag} \
          --dest-tls-verify=false
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