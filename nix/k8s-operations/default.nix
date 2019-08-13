{
  pkgs, 
  writeScript,
  writeScriptBin,
  callPackage,
  kubenix,
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

  helpers = callPackage ./helpers.nix {};
  local = callPackage ./local.nix { inherit helpers; };
in
with helpers;
rec {
  inherit local;
  inherit helpers;

  save-resources = 
    let
      loc = project-config.project.resources.yaml.folder;
      drop-hash = ''sed -e '/kubenix\/hash/d' '';
      crds = 
        crds-command 
          (desc: ''
            ${log.info "Saving crd for ${desc.name}, to: ${loc}"}
            cat ${desc.value} | ${drop-hash} > ${loc}/${desc.name}-crd.yaml
          '');
      resources =
        resources-command 
          (desc: ''
            ${log.info "Saving resources for ${desc.name}, to: ${loc}"}
            cat ${desc.value} | ${drop-hash} > ${loc}/${desc.name}-resources.yaml
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

      wait-for-job = wait-for {
        service = "job";
        condition = "condition=complete";
        resource = "job";
        extraArgs = "--all";
      };

      wait-for-crd = wait-for {
        service = "crd";
        condition = "condition=established";
        resource = "crd";
        extraArgs = "--all";
      };
    in
      writeScriptBin "apply-k8s-crd" ''
        ${crds}
        ${wait-for-job}
        ${wait-for-crd}
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

  inherit docker-images;
}