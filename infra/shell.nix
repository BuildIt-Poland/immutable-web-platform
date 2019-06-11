# idea based on https://github.com/WeAreWizards/blog/blob/master/content/articles/sharing-deployments-with-nixops.md
# this state is required to be able to do a gitops
{
  pkgs ? (import ../nix {}).pkgs,
  kms ? ""
}:
with pkgs;
# remote state reconcilation
let
  # TODO try to export json file and import to clean state - should be fast enough
  # nixops --export --all > state.json
  # sops encode
  # sops decode
  # nixops import -
  # making state lock here would be easy as well - perhaps time to make a cli for it?

  locker = remote-state.package;

  # this should be stateless
  # when doing deploy we should as
  encode-state = pkgs.writeScript "encode-state" ''
    ${pkgs.sops}/bin/sops --kms ${kms} -e localstate.nixops > infra.state
  '';

  decode-state = pkgs.writeScript "decode-state" ''
    ${pkgs.sops}/bin/sops -d infra.state > localstate.nixops
  '';

  state-export = pkgs.writeScript "export-state" ''
    ${pkgs.nixops}/bin/nixops export --all > ${paths.localstate-json}
  '';

  state-import = pkgs.writeScript "import-state" ''
    if [ -f "${paths.localstate-json}" ]; then
      ${pkgs.nixops}/bin/nixops import --include-keys < ${paths.localstate-json}
    fi
  '';

  state-reconcile = pkgs.writeScript "reconcile-state" ''
    cat ${paths.localstate-json}
    cat ${paths.remotestate-json}
  '';

  # it is required to avoid fixed paths
  expressions = {
    ec2 = "<ec2.nix>";
    configuration = "<configuration.nix>";
    binary-store = "<binarystore.nix>";
  };
  paths = {
    localstate-sqlite = "localstate.nixops";
    localstate-json = "localstate.nixops.json";
    remotestate-json = "remotestate.nixops.json";
  };

    # ${pkgs.nixops}/bin/nixops export --all --state localstate.nixops > state.json
    # ${decode-state}
    # ${encode-state}
  nixops = pkgs.writeScriptBin "nixops" ''
    ${locker}/bin/locker lock

    ${locker}/bin/locker download-state --file ${paths.localstate-json} > ${paths.remotestate-json}
    ${state-reconcile}

    ${state-import}
    ${pkgs.nixops}/bin/nixops $*
    ${state-export}

    // before upload do reconcilation not at the begining!
    ${locker}/bin/locker upload-state --file ${paths.localstate-json}
    ${locker}/bin/locker unlock
  '';

  nixops-create = pkgs.writeScriptBin "nixops-create" ''
    ${nixops}/bin/nixops create '<configuration.nix>' '<virtualbox.nix>' -d ${env-config.projectName}-local
  '';
    # ${nixops}/bin/nixops deploy -d $(DEPLOYMENT_NAME)-local --kill-obsolete --allow-reboot


  # TODO port make scripts here
  # TODO compare states
in
mkShell {
  buildInputs = [
    nixops
    nixops-create
    locker

    pkgs.nodejs
    pkgs.sops
  ];
  NIX_PATH="${./.}";
  NIXOPS_STATE="localstate.nixops";
  PROJECT_NAME = env-config.projectName;
  shellHook = ''
  '';
}