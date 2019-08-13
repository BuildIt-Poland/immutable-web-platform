{pkgs, log, lib, callPackage, buildGoPackage, fetchFromGitHub, project-config}:
let
  nix-terraform = callPackage ./terraform-provider-nix.nix {};
  nix-provider-nix = nix-terraform;
  terraform = pkgs.terraform_0_12.withPlugins (plugins: [
    plugins.aws
    plugins.null
    plugins.random
    plugins.local
    plugins.template
    plugins.archive
    plugins.external
    nix-provider-nix
  ]);

  vars = project-config.terraform.vars;
  backend-vars = project-config.terraform.backend-vars;

  generate-var-file = 
    let
      make-var = name: lib.attrsets.setAttrByPath ["variable" "${name}" "default"];
      variables = 
        builtins.attrValues (builtins.mapAttrs make-var vars);
    in
      lib.foldl lib.recursiveUpdate {} variables;

  to-var-file = data:
    lib.generators.toKeyValue {} 
      (builtins.mapAttrs (x: y: "\"${y}\"") data);

  backend-vars-file = pkgs.writeText "tf-backend-values.hcl" ''
    ${to-var-file backend-vars}
  '';

  vars-file = pkgs.writeText "print-tf-env-vars" ''
    ${to-var-file vars}
  '';

  print-vars = ''
    ${log.info "Backend vars"}
    cat ${backend-vars-file}

    ${log.info "Vars"}
    cat ${vars-file}
  '';

  # cat ${vars-file} > vars.generated.tfvars
  save-vars-to-cwd = ''
    echo '${lib.generators.toJSON {} generate-var-file}' | jq . > vars.generated.tf.json
  '';

  wrap-terraform-init = pkgs.writeScript "wrap-terraform-init" ''
    extraArgs="-backend-config=${backend-vars-file} -backend-config="key=${vars.project_prefix}/$(basename $(pwd))""
    [[ $1 = "init" ]] || extraArgs=""
    ${save-vars-to-cwd}
    ${terraform}/bin/terraform $* $extraArgs
  '';
in 
  pkgs.runCommand "terraform" { buildInputs = [pkgs.makeWrapper]; } ''
    mkdir -p $out/bin
    makeWrapper ${wrap-terraform-init} $out/bin/terraform
  ''