  upload_docker_image = nixpkgs.writeShellScriptBin "upload_docker_image" ''
    eval $(${nixpkgs.minikube-eisl}/bin/minikube docker-env)
    output_tar=$1
    external_tag=$2

    tag="latest"

    name=$(echo $TEST_TARGET |  cut -d ':' -f 1 | cut -c 3-)

    echo "Uploading docker image, $output_tar, with tag, $external_tag"

    if [ -f "$output_tar" ]; then
      docker load -i $output_tar
      docker tag bazel/$name:$external_tag bazel/$name:$tag
      docker tag bazel/$name:$external_tag bazel/$name:latest
    fi
  '';

  k8s-autobuild = nixpkgs.writeShellScriptBin "k8s-autobuild" ''
    echo "Updating kubernetes descriptors with params: $*"

    eval $(${nixpkgs.minikube-eisl}/bin/minikube docker-env)
    output_tar=$1
    service_name=$2

    ${upload_docker_image}/bin/upload_docker_image $1 docker
    name=$(echo $TEST_TARGET |  cut -d ':' -f 1 | cut -c 3-)
    ${nixpkgs.kustomize}/bin/kustomize build ${rootFolder}/$name/k8s | ${nixpkgs.kubectl}/bin/kubectl apply -f -
    ${nixpkgs.kubectl}/bin/kubectl rollout restart $service_name -n service
  '';

  k8s-delete = nixpkgs.writeShellScriptBin "k8s-delete" ''
    service_name=$2
    name=$(echo $TEST_TARGET |  cut -d ':' -f 1 | cut -c 3-)
    kustomize build ${rootFolder}/$name/k8s | kubectl delete -f -
  '';