# INSPIRATION: https://github.com/WeAreWizards/blog/blob/master/content/articles/sharing-deployments-with-nixops.md
# INFO: this state is required to be able to do a gitops
{
  pkgs ? (import ../nix {}).pkgs,
  machinesConfigPath ? ./machines.json,
  local ? false,
  kms ? ""
}:
with pkgs;
with remote-state.package;
let

  paths = {
    state-sql = "state.nixops";
  };

  machines = pkgs.callPackage ./machines.nix {
    inherit machinesConfigPath;
  };

  nixops = pkgs.callPackage ./deployer {
    inherit paths;
  };

  deployment-scripts = pkgs.callPackage ./deployer/deployment-scripts.nix {
    inherit nixops machines;
  };
in
mkShell {
  buildInputs = [
    # nixops wrapper
    nixops

    # remote state locker
    remote-state-cli
    remote-state-aws-infra

    # deployment scripts
    (if !local 
      then (builtins.attrValues deployment-scripts.deploy-ec2)
      else (builtins.attrValues deployment-scripts.deploy-vbox))
  ];

  PROJECT_NAME = env-config.projectName;

  shellHook = ''
    ${if !local 
      then "export NIXOPS_STATE=${paths.state-sql}" 
      else ""}

    export NIX_PATH="$NIX_PATH:$(pwd)"
    echo "You are now entering the remote deployer ... have fun!"
  '';
}