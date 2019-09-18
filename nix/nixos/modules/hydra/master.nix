{pkgs, config, lib, ...}: 
let
  project = pkgs.project-config.project;
  host-name = project.make-sub-domain "hydra";
in 
with lib;
{
  imports = [ 
    ./proxy.nix
    ./gc.nix
    ./ssh.nix
    ./users.nix
  ];

  options.services.hydra = {
    workers = mkOption {
      default = [{
        hostName = "localhost";
        systems = [ "x86_64-linux" ];
        maxJobs = 6;
        supportedFeatures = [ ];
      }];
    };
  };

  config = {
    assertions = singleton {
      assertion = pkgs.system == "x86_64-linux";
      message = "unsupported system ${pkgs.system}";
    };

    networking.firewall.allowedTCPPorts = [ config.services.hydra.port ];

    nix = {
      # nix.useSandbox
      distributedBuilds = true;
      buildMachines = config.services.hydra.workers;
      extraOptions = "auto-optimise-store = true";
    };

    environment.etc = pkgs.lib.singleton {
      target = "nix/id_bitbucket";
      # this is kind a cool
      # source = pkgs.project-config.bitbucket.ssh-keys.priv;
      # FIXME should be in module definition
      source = pkgs.project-config.bitbucket.ssh-keys.location;
      uid = config.ids.uids.hydra;
      gid = config.ids.gids.hydra;
      mode = "0400";
    };

    
    #  hydra.conf: binary_cache_dir is deprecated and ignored. use store_uri=file:// instead
    #  hydra.conf: binary_cache_secret_key_file is deprecated and ignored. use store_uri=...?secret-key= instead
    services.hydra = {
      enable = true;
      useSubstitutes = true;
      hydraURL = host-name;
      notificationSender = project.authorEmail;
      buildMachinesFiles = [];
      extraConfig = ''
        store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/${host-name}/secret
        binary_cache_secret_key_file = /etc/nix/${host-name}/secret
        binary_cache_dir = /var/lib/hydra/cache
      '';
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      identMap = ''
        hydra-users hydra hydra
        hydra-users root postgres
      '';
      #   hydra-users hydra-queue-runner hydra
      #   hydra-users hydra-www hydra
      #   hydra-users postgres postgres
      dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
    };

    systemd.services.add-bitbucket-key = {
      enable = true;
      description = "Add bitbucket key";
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
      after = [ "hydra-init.service" ];
      environment = builtins.removeAttrs (config.systemd.services.hydra-init.environment) ["PATH"];
      # path = [ ];
      script = ''
        # private bitbucket repo key
        /run/current-system/sw/bin/mkdir -p /var/lib/hydra/.ssh/
        /run/current-system/sw/bin/cp /etc/nix/id_bitbucket ~/.ssh/id_rsa

        # agent
        eval "$(/run/current-system/sw/bin/ssh-agent -s)"

        # ssh identity
        /run/current-system/sw/bin/ssh-add ~/.ssh/id_rsa
      '';
    };
    # sudo su hydra

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