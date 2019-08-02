{
  pkgs, 
  writeScript,
  writeScriptBin,
  callPackage,
  project-config,
  log,
  lib
}:
let
  resourceMap = 
    {resources, path}:
    transformer:
      let
        k8s-crd = lib.mapAttrs (name: lib.getAttrFromPath path) resources;
        name-value-pairs = builtins.attrValues (lib.mapAttrs lib.nameValuePair k8s-crd);
      in
        lib.concatMapStringsSep "\n" transformer name-value-pairs;

  crds-command = resourceMap {
    resources = project-config.modules.kubernetes;
    path = ["yaml" "crd"];
  };

  resources-command = resourceMap {
    resources = project-config.modules.kubernetes;
    path = ["yaml" "objects"];
  };

  docker-images = resourceMap {
    resources = project-config.modules.docker;
    path = [];
  };
in
rec {
  local = callPackage ./local.nix {};

  kubectl-apply = resources: writeScript "apply-resources" ''
    ${log.info "Applying resources ${resources}"}
    cat ${resources} | ${pkgs.kubectl}/bin/kubectl apply --record -f -
  '';

  wait-for = resource: condition: writeScript "wait-for-condition" ''
    ${pkgs.kubectl}/bin/kubectl wait ${resource} --for condition=${condition} --all --timeout=300s
  '';

  save-resources = 
    let
      loc = project-config.project.resources.yaml.folder;
      drop-hash = ''sed -e '/kubenix\/hash/d' '';
      crds = 
        crds-command 
          (desc: ''
            ${log.info "Saving crd for ${desc.name}, to: ${loc}"}
            cat ${desc.value} | ${drop-hash} > ${loc}/${desc.name}.yaml
          '');
      resources =
        resources-command 
          (desc: ''
            ${log.info "Saving resources for ${desc.name}, to: ${loc}"}
            cat ${desc.value} | ${drop-hash} > ${loc}/${desc.name}.yaml
          '');
    in
      writeScriptBin "save-resources" ''
        ${crds}
        ${resources}
      '';

  apply-crd = 
    let
      crds = 
        crds-command 
          (desc: ''
            ${log.info "Applying crd for ${desc.name}"}
            ${kubectl-apply desc.value}
          '');
    in
    writeScriptBin "apply-k8s-crd" ''
      ${crds}
      ${wait-for "job" "complete"}
      ${wait-for "crd" "established"}
    '';

  apply-resources = 
    let
      resources = 
        resources-command
          (desc: ''
            ${log.info "Applying kubernetes resources for ${desc.name}"}
            ${kubectl-apply desc.value}
          '');
    in
      writeScriptBin "apply-k8s-resources" ''
        ${resources}
      '';

  push-docker-images-to-local-cluster = 
    let
      images = docker-images (desc: 
          let
            docker = desc.value;
          in
          ''
            ${log.info "Pushing docker image, for ${desc.name} to local cluster: ${docker.name}:${docker.tag}"}
            ${pkgs.docker}/bin/docker load -i ${docker.image}
          '');
      in
      writeScriptBin "push-docker-images-to-local-cluster" ''
        eval $(minikube docker-env -p ${project-config.project.name})
        ${images}
      '';

  push-to-docker-registry = writeScriptBin "push-to-docker-registry" "";
    # (lib.concatMapStrings 
    #   (docker-images: ''
    #     ${docker.copyDockerImages { 
    #       images = docker-images; 
    #       dest = project-config.docker.destination;
    #     }}/bin/copy-docker-images
    #   '') cluster.images);
}