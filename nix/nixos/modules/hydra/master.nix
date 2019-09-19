{pkgs, config, lib, ...}: 
let
  project = pkgs.project-config.project;
  host-name = config.networking.hostName;
  narCache = "/var/cache/hydra/nar-cache";
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

    environment.systemPackages = [ 
      pkgs.zsh
      pkgs.hydra-cli
    ];

    nix = {
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

    services.hydra = 
      let
        bucket = pkgs.project-config.aws.s3-buckets.worker-cache;
      in
      {
        enable = true;
        useSubstitutes = true;
        hydraURL = config.networking.hostName;
        notificationSender = project.authorEmail;
        buildMachinesFiles = [];
        extraConfig = ''
          store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/${host-name}/secret
        '';
          # store_uri = s3://future-is-comming-dev-worker-binary-store?secret-key=/etc/nix/${host-name}/secret&write-nar-listing=1&ls-compression=br&log-compression=br
          # store_uri = s3://${bucket}?secret-key=/etc/nix/${host-name}/secret&write-nar-listing=1&ls-compression=br&log-compression=br

        # # THIS works
        # store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/${host-name}/secret

        # FIXME - it has to be bucket!
        # cannot build with such setup
        # store_uri = s3://${bucket}?secret-key=/etc/nix/${host-name}/secret&write-nar-listing=1&ls-compression=br&log-compression=br
        # nar_buffer_size = ${let gb = 10; in toString (gb * 1024 * 1024 * 1024)}
        # upload_logs_to_binary_cache = true
        # log_prefix = https://${bucket}.s3.amazonaws.com/
        # server_store_uri = https://cache.nixos.org?local-nar-cache=${narCache}
        # binary_cache_public_uri = https://cache.nixos.org
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