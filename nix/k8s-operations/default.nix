{
  pkgs, 
  writeScript,
  writeScriptBin,
  callPackage,
  kubenix,
  project-config,
  lib
}:
with lib;
let
  resourceMap = 
    {resources, path}:
    transformer:
      let
        k8s-crd = mapAttrs (name: getAttrFromPath path) resources;
        name-value-pairs = builtins.attrValues (mapAttrs nameValuePair k8s-crd);
      in
        concatMapStringsSep "\n" transformer name-value-pairs;

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

  should-skip-resource = ok: fail: {name, value}@arg: 
    let
      shouldSkip = builtins.elem "skip" (lib.splitString "-" name);
    in
      if shouldSkip 
        then (fail arg) 
        else (ok arg);
in
with helpers;
rec {
  inherit helpers;

  save-resources = 
    let
      loc = project-config.project.resources.yaml.folder;
      save-any-resource = 
        suffix: desc:
          let
            drop-hash = ''sed -e '/kubenix\/hash/d' '';
            priority-name = lib.splitString "-" desc.name;
            priority = lib.head priority-name;
            name = lib.last priority-name;
          in
            ''
              target="${project-config.kubernetes.target}"
              env="${project-config.environment.type}"
              location="${loc}/$target/$env/${priority}"
              file=${name}-${suffix}.yaml

              mkdir -p $location

              ${log.info "Saving ${suffix} for ${name}, to: $location/$file"}
              cat ${desc.value} | ${drop-hash}  > $location/$file
            '';

      crds = crds-command (save-any-resource "crd");
      resources = resources-command (save-any-resource "resources");
    in
      writeScriptBin "save-resources" ''
        ${crds}
        ${resources}
      '';

  apply-crd = 
    let
      crds = 
        crds-command 
          (should-skip-resource
            (desc: ''
              ${log.info "Applying crd for ${desc.name}"}
              ${kubectl-apply desc.value}
            '')
            (desc: "${log.message "Skipping crd for ${desc.name}"}")
          );

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
          (should-skip-resource
            (desc: ''
              ${log.info "Applying kubernetes resources for ${desc.name}"}
              ${kubectl-apply desc.value}
            '')
            (desc: "${log.message "Skipping resource for ${desc.name}"}")
          );
    in
      writeScriptBin "apply-k8s-resources" ''
        ${resources}
      '';

  inherit docker-images;
}