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
        systems = [ "x86_64-linux" "i686-linux" ];
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
      distributedBuilds = true;
      buildMachines = config.services.hydra.workers;
      extraOptions = "auto-optimise-store = true";
    };

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

          # done
          touch ~hydra/.setup-is-complete
        fi
      '';
    };
  };
}