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
  # TODO this should be in k8s-resources - too many places with charts and jsons
  # ${apply-resources charts.istio-cni-yaml}
  apply-istio-crd = writeScript "apply-istio-crd" ''
    ${apply-resources charts.istio-init-yaml}
    ${wait-for "job" "complete"}
    ${wait-for "crd" "established"}
  '';

  # TODO enable flag - print resources
  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    ${log.important "Applying functions helm charts"}
    cat ${cluster.k8s-functions-resources} > resources/function-resources.yaml
    ${apply-resources cluster.k8s-functions-resources}
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    ${log.important "Applying cluster helm charts"}

    ${apply-istio-crd}

    cat ${cluster.k8s-cluster-resources} > resources/cluster-resources.yaml
    ${apply-resources cluster.k8s-cluster-resources}
  '';

  create-private-registry = writeScriptBin "create-private-registry" ''
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
    # IP -> docker inspect --format '{{ .NetworkSettings.IPAddress }}' registry

docker exec future-is-comming-control-plane bash -c 'cat <<EOF > /etc/docker/daemon.json
{
    "insecure-registries": ["172.17.0.3:5000"]
}
EOF'

    docker exec future-is-comming-control-plane bash -c 'kill -s SIGHUP $(pgrep dockerd)'
  '';

  # localhost:5000 should be taken from env-config
  push-docker-images-to-local-cluster = writeScriptBin "push-docker-images-to-local-cluster"
    (lib.concatMapStrings 
      (docker-image: ''
        ${log.important "Pushing docker image to local cluster: ${docker-image}, ${docker-image.imageName}/${docker-image.imageTag}"}
        ${pkgs.skopeo}/bin/skopeo \
          --insecure-policy \
          copy \
          docker-archive://${docker-image} \
          docker://localhost:32001/${docker-image.imageName}/${docker-image.imageTag} \
          --dest-tls-verify=false
      '') cluster.images);

  # ${pkgs.kind}/bin/kind load image-archive --name ${env-config.projectName} ${docker-image}

  push-to-docker-registry = writeScriptBin "push-to-docker-registry"
    (lib.concatMapStrings 
      (docker-images: ''
        ${docker.copyDockerImages { 
          images = docker-images; 
          dest = env-config.docker.destination;
        }}/bin/copy-docker-images
      '') cluster.images);
}