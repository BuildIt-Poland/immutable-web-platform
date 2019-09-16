{pkgs, lib, callPackage, buildGoPackage, fetchFromGitHub, project-config,  buildEnv, terraform-providers}:
let
  pluginList = plugins: [
    plugins.aws
    plugins.null
    plugins.random
    plugins.local
    plugins.template
    plugins.archive
    plugins.external
    plugins.tls
    plugins.random
    plugins.archive
  ];

  plugins = plugins terraform-providers; 

  terraform = (pkgs.terraform_0_12).withPlugins pluginList;
  # .overrideAttrs (x: { patches = [./thrift.patch]; });

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
    ${lib.log.info "Backend vars"}
    cat ${backend-vars-file}

    ${lib.log.info "Vars"}
    cat ${vars-file}
  '';

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
  # https://www.terraform.io/docs/configuration/providers.html#plugin-names-and-versions
  # export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/terraform/default.nix
  # actualPlugins = plugins terraform.plugins;
  # --set NIX_TERRAFORM_PLUGIN_DIR "${buildEnv { name = "tf-plugin-env"; paths = actualPlugins; }}/bin" \
  pkgs.runCommand "terraform" { buildInputs = [pkgs.makeWrapper]; } ''
    mkdir -p $out/bin
    makeWrapper ${wrap-terraform-init} $out/bin/terraform
  ''