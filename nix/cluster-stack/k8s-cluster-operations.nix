{
  pkgs, 
  env-config, 
  writeScript,
  writeScriptBin,
  cluster,
  log,
  lib
}:
with cluster;
rec {

  apply-resources = resources: writeScript "apply-resources" ''
    ${log.important "Applying resources ${resources}"}
    cat ${resources} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  wait-for = resource: condition: writeScript "wait-for-condition" ''
    ${pkgs.kubectl}/bin/kubectl wait ${resource} --for condition=${condition} --all --timeout=300s
  '';

  save-resources = 
    let
      loc = env-config.resources.yaml.location;
      drop-hash = ''sed -e '/kubenix\/hash/d' '';
    in
      writeScriptBin "save-resources" ''
        ${log.important "Saving yamls to: $PWD${loc}"}
        cat ${resources.crd} | ${drop-hash} > $PWD${loc}/crd.yaml
        cat ${resources.cluster} | ${drop-hash} > $PWD${loc}/cluster.yaml
        cat ${resources.functions} | ${drop-hash} > $PWD${loc}/functions.yaml
      '';

  apply-cluster-crd = writeScriptBin "apply-cluster-crd" ''
    ${apply-resources resources.crd}
    ${wait-for "job" "complete"}
    ${wait-for "crd" "established"}
  '';

  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    ${log.important "Applying functions helm charts"}
    ${apply-resources resources.functions}
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    ${log.important "Applying cluster helm charts"}
    ${apply-resources resources.cluster}
  '';

  push-docker-images-to-local-cluster = writeScriptBin "push-docker-images-to-local-cluster"
    (lib.concatMapStrings 
      (docker-image: ''
        eval $(minikube docker-env -p ${env-config.projectName})
        ${log.important "Pushing docker image to local cluster: ${docker-image}, ${docker-image.imageName}:${docker-image.imageTag}"}
        ${pkgs.docker}/bin/docker load -i ${docker-image}
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