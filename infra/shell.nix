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
    inherit paths local;
  };

  deployment-scripts = pkgs.callPackage ./deployer/deployment-scripts.nix {
    inherit nixops machines local;
  };
in
# TODO make modules as it is done for root/shell
mkShell {
  buildInputs = [
    # nixops wrapper
    nixops
    nodejs

    # remote state locker
    remote-state-cli
    remote-state-aws-infra

    # deployment scripts
    (if !local 
      then (builtins.attrValues deployment-scripts.deploy-ec2)
      else (
           builtins.attrValues deployment-scripts.deploy-vbox
        ++ builtins.attrValues deployment-scripts.deploy-tester
      ))
  ];

  PROJECT_NAME = project-config.project.name;

  # THIS NODE_PATH is a hack - wrap npx and export PATH there - npx does not take into account $PATH
  shellHook = ''
    ${if !local 
      then "export NIXOPS_STATE=${paths.state-sql}" 
      else ""}

    export NODE_PATH="$NODE_PATH:${remote-state-aws-infra.node_modules}"
    export NIX_PATH="$NIX_PATH:$(pwd)"
    echo "You are now entering the remote deployer ... have fun!"
  '';
}