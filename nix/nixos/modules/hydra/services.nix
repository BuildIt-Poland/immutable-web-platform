{pkgs, config, lib, ...}: 
let
  project = pkgs.project-config.project;
  host-name = config.networking.hostName;
in 
with lib;
{
  imports = [];

  config = {
    systemd.services.hydra-quick-project-setup = {
      enable = true;
      description = "One time hydra project setup";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "hydra";
        Group = "hydra";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "sshd.service" ];
      unitConfig = {
        ConditionPathExists = "/etc/nix/id_bitbucket";
      };
      after = [ "hydra-init.service" "hydra-server.service" "hydra-manual-setup.service" ];
      environment = (builtins.removeAttrs (config.systemd.services.hydra-init.environment) ["PATH"]) // {
        HYDRA_HOST = "http://localhost:${toString config.services.hydra.port}";
        HYDRA_PASSWORD = "admin";
        HYDRA_USER = "admin";
      };
      path = [ pkgs.hydra-cli ];
      script = ''
        if [ ! -e ~hydra/.basic-project-setup ]; then
          # private bitbucket repo key
          /run/current-system/sw/bin/mkdir -p /var/lib/hydra/.ssh/

          if [ ! -e ~/.ssh/id_rsa ]; then
            /run/current-system/sw/bin/cp /etc/nix/id_bitbucket ~/.ssh/id_rsa
          fi

          # agent
          eval "$(/run/current-system/sw/bin/ssh-agent -s)"

          # ssh identity
          /run/current-system/sw/bin/ssh-add ~/.ssh/id_rsa

          # initial project
          hydra-cli project-create ${project.name}
          hydra-cli jobset-create ${project.name} binary-store /etc/source/pipeline/nix-builder/jobset.json

          # done
          touch ~hydra/.basic-project-setup
        fi
      '';
    };

    systemd.services.hydra-manual-setup = {
      description = "Create Admin User for Hydra";
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      wantedBy = [ "multi-user.target" ];
      requires = [ "hydra-init.service" ];
      after = [ "hydra-init.service" ];
      environment = builtins.removeAttrs (config.systemd.services.hydra-init.environment) ["PATH"];
      script = ''
        if [ ! -e ~hydra/.setup-is-complete ]; then
          # create signing keys
          /run/current-system/sw/bin/install -d -m 551 /etc/nix/${host-name}
          /run/current-system/sw/bin/nix-store --generate-binary-cache-key ${host-name} /etc/nix/${host-name}/secret /etc/nix/${host-name}/public
          /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/${host-name}
          /run/current-system/sw/bin/chmod 440 /etc/nix/${host-name}/secret
          /run/current-system/sw/bin/chmod 444 /etc/nix/${host-name}/public

          # create cache
          /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
          /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache

          # user
          /run/current-system/sw/bin/hydra-create-user admin --full-name 'SUPER ADMIN' --email-address 'EMAIL' --password admin --role admin

          # done
          touch ~hydra/.setup-is-complete
        fi
      '';
    };
  };
}