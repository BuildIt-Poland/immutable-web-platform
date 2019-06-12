# INSPIRATION: https://github.com/WeAreWizards/blog/blob/master/content/articles/sharing-deployments-with-nixops.md
# INFO: this state is required to be able to do a gitops
{
  pkgs ? (import ../nix {}).pkgs,
  kms ? ""
}:
with pkgs;
let
  locker = remote-state.package;

  paths = {
    state-sql = "state.nixops";
    state-json = "state.nixops.json";
  };

  # ENCODE / DECODE
  # use --before-upload to encode data before uploading
  # pipe when download-state and decode

  # encode-state = pkgs.writeScript "encode-state" ''
  #   ${pkgs.sops}/bin/sops --kms ${kms} -e localstate.nixops > infra.state
  # '';

  # decode-state = pkgs.writeScript "decode-state" ''
  #   ${pkgs.sops}/bin/sops -d infra.state > localstate.nixops
  # '';

  # TODO this should be a bit smarter - check first whether there are differences
  keep-it-stateless = pkgs.writeScript "keep-it-stateless" ''
    rm ${paths.state-sql}
  '';

  state-import = pkgs.writeScript "import-state" ''
    ${keep-it-stateless}

    ${locker}/bin/locker download-state --file ${paths.state-json} \
      | ${pkgs.nixops}/bin/nixops import --include-keys 
  '';

  # INFO: interactive mode does not work when piping - investigate
  # ${pkgs.nixops}/bin/nixops export --all \
  #   | ${locker}/bin/locker upload-state --stdin

  upload-remote-state = pkgs.writeScriptBin "upload-remote-state" ''
    IS_LOCKED=$(${locker}/bin/locker status)
    echo "Remote state is locked? $IS_LOCKED"

    if [ "$IS_LOCKED" == "false" ]; then
      ${locker}/bin/locker upload-state --from "${pkgs.nixops}/bin/nixops export --all"
    fi
  '';

  import-remote-state = pkgs.writeScriptBin "import-remote-state" ''
    ${locker}/bin/locker import-state \
      --from "${pkgs.nixops}/bin/nixops export --all" \
      --before-to "rm ${paths.state-sql}" \
      --to "${pkgs.nixops}/bin/nixops import --include-keys"
  '';
#  --from "${pkgs.nixops}/bin/nixops export --all"
     # | ${pkgs.nixops}/bin/nixops import --include-keys 

  nixops = pkgs.writeScriptBin "nixops" ''
    ${pkgs.nixops}/bin/nixops $(${locker}/bin/locker rewrite-arguments --input "$*" --cwd $(pwd))
  '';
in
mkShell {
  buildInputs = [
    nixops
    locker

    upload-remote-state
    import-remote-state

    pkgs.nodejs
    pkgs.sops
  ];
  NIX_PATH = "${./.}";
  NIXOPS_STATE = paths.state-sql;
  PROJECT_NAME = env-config.projectName;
  shellHook = ''
    echo "You are now entering the remote deployer ... have fun!"
  '';
}