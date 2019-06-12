# INSPIRATION: https://github.com/WeAreWizards/blog/blob/master/content/articles/sharing-deployments-with-nixops.md
# INFO: this state is required to be able to do a gitops
{
  pkgs ? (import ../nix {}).pkgs,
  kms ? ""
}:
with pkgs;
let
  locker = remote-state.package.remote-state-cli;

  paths = {
    state-sql = "state.nixops";
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

  keep-nixops-stateless = pkgs.writeScript "keep-it-stateless" ''
    rm ${paths.state-sql}
  '';

  nixops-export-state = pkgs.writeScript "nixops-export-state" ''
    ${pkgs.nixops}/bin/nixops export --all
  '';

  nixops-import-state = pkgs.writeScript "nixops-import-state" ''
    ${pkgs.nixops}/bin/nixops import --include-keys
  '';

  import-remote-state = pkgs.writeScriptBin "import-remote-state" ''
    ${locker}/bin/locker import-state \
      --from "${nixops-export-state}" \
      --before-to "${keep-nixops-stateless}" \
      --to "${nixops-import-state}"
  '';

  upload-remote-state = pkgs.writeScriptBin "upload-remote-state" ''
    ${locker}/bin/locker upload-state \
      --from "${pkgs.nixops}/bin/nixops export --all"
  '';

  nixops = pkgs.writeScriptBin "nixops" ''
    ${pkgs.nixops}/bin/nixops $(${locker}/bin/locker rewrite-arguments --input "$*" --cwd $(pwd))
  '';
in
mkShell {
  buildInputs = [
    remote-state.package.remote-state-cli
    remote-state.package.remote-state-aws-infra

    upload-remote-state
    import-remote-state
    nixops

    pkgs.sops
  ];
  NIX_PATH = "${./.}";
  NIXOPS_STATE = paths.state-sql;
  PROJECT_NAME = env-config.projectName;
  shellHook = ''
    echo "You are now entering the remote deployer ... have fun!"
  '';
}