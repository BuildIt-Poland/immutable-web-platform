# INSPIRATION: https://github.com/WeAreWizards/blog/blob/master/content/articles/sharing-deployments-with-nixops.md
# INFO: this state is required to be able to do a gitops
{
  pkgs ? (import ../nix {}).pkgs,
  kms ? ""
}:
with pkgs;
let
  locker = remote-state.package;

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
    rm ${paths.localstate-sqlite}
  '';

  state-import = pkgs.writeScript "import-state" ''
    ${keep-it-stateless}
    ${locker}/bin/locker download-state --file ${paths.localstate-json} | ${pkgs.nixops}/bin/nixops import --include-keys 
  '';

  reconcile-remote-state = pkgs.writeScriptBin "reconcile-remote-state" ''
    ${pkgs.nixops}/bin/nixops export --all | ${locker}/bin/locker upload-state --stdin
  '';

  paths = {
    localstate-sqlite = "localstate.nixops";
    localstate-json = "localstate.nixops.json";
  };

  # TODO not sure if there should be autoupload
  # TODO add possibility to reconcile local-state and remote one -> import should be interactive as well
  nixops = pkgs.writeScriptBin "nixops" ''
    IS_LOCKED=$(${locker}/bin/locker status)
    echo "Remote state is locked? $IS_LOCKED"

    if [ "$IS_LOCKED" == "false" ]; then
      ${state-import}
      ${pkgs.nixops}/bin/nixops $(${locker}/bin/locker rewrite-arguments --input "$*")
      ${reconcile-remote-state}/bin/reconcile-remote-state
    fi
  '';
in
mkShell {
  buildInputs = [
    nixops
    locker

    reconcile-remote-state

    pkgs.nodejs
    pkgs.sops
  ];
  NIX_PATH = "${./.}";
  NIXOPS_STATE = paths.localstate-sqlite;
  PROJECT_NAME = env-config.projectName;
  shellHook = ''
    echo "You are now entering the remote deployer ... have fun!"
  '';
}