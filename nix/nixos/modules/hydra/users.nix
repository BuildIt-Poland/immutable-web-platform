{pkgs, config,...}: 
let
  project = pkgs.project-config.project;
in {
  config = {
    nix = {
      trustedUsers = ["hydra" "hydra-evaluator" "hydra-queue-runner" "root"];
    };

    users = {
      mutableUsers = false;

      # users.hydra-www.uid = config.ids.uids.hydra-www;
      # users.hydra-queue-runner.uid = config.ids.uids.hydra-queue-runner;
      users.hydra.uid = config.ids.uids.hydra;
      groups.hydra.gid = config.ids.gids.hydra;

      # FIXME
      users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
      # extraUsers.root.openssh.authorizedKeys.keys = pkgs.lib.singleton ''
      #   command="nice -n20 nix-store --serve --write" ${pkgs.lib.readFile ./id_buildfarm.pub}
      # '';
    };
  };
}