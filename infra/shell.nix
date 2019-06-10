# idea based on https://github.com/WeAreWizards/blog/blob/master/content/articles/sharing-deployments-with-nixops.md
# this state is required to be able to do a gitops
{
  pkgs ? (import ../nix {}).pkgs,
  kms
}:
# What I need
# remote state -> s3 with lambda
# check aws-cdk
with pkgs;
# remote state reconcilation
let
  # TODO try to export json file and import to clean state - should be fast enough
  # nixops --export --all > state.json
  # sops encode
  # sops decode
  # nixops import -
  # making state lock here would be easy as well - perhaps time to make a cli for it?
  encode-state = pkgs.writeScript "encode-state" ''
  ${pkgs.sops}/bin/sops --kms ${kms} -e localstate.nixops > infra.state
  '';

  decode-state = pkgs.writeScript "decode-state" ''
    ${pkgs.sops}/bin/sops -d infra.state > localstate.nixops
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
  };

  export-state-to-json = ''
    ${pkgs.nixops}/bin/nixops export --all --state ${paths.localstate-sqlite} > ${paths.localstate-json}
  '';

  import-state-from-json = ''
    ${pkgs.nixops}/bin/nixops import --include-keys --state ${paths.localstate-sqlite} < ${paths.localstate-json}
  '';

  nixops-with-state = pkgs.writeScriptBin "nixops" ''
    ${decode-state}
    ${pkgs.nixops}/bin/nixops $* --state localstate.nixops
    ${pkgs.nixops}/bin/nixops export --all --state localstate.nixops > state.json
    ${encode-state}
  '';

  # TODO port make scripts here
  # TODO compare states
in
mkShell {
  buildInputs = [
    nixops-with-state
    remote-state.package

    pkgs.nodejs
    pkgs.sops
  ];
  NIX_PATH="${./.}";
  PROJECT_NAME = env-config.projectName;
  shellHook = ''
  '';
}