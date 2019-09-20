{pkgs, config, lib, ...}: 
let
  project = pkgs.project-config.project;
  host-name = config.networking.hostName;
  narCache = "/var/cache/hydra/nar-cache";
  aws = pkgs.project-config.aws;
  store-bucket = aws.s3-buckets.worker-cache;
in 
with lib;
{
  imports = [ 
    ./proxy.nix
    ./gc.nix
    ./ssh.nix
    ./services.nix
    ./users.nix
  ];

  options.services.hydra = {
    workers = mkOption {
      default = [{
        hostName = "localhost";
        systems = [ "x86_64-linux" ];
        maxJobs = 6;
        supportedFeatures = ["builtin" "big-parallel" ];
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

    services.hydra = {
      enable = true;
      useSubstitutes = true;
      hydraURL = config.networking.hostName;
      notificationSender = project.authorEmail;
      buildMachinesFiles = [];
      # locally -> without store: store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/${host-name}/secret
      extraConfig = ''
        store_uri = s3://${store-bucket}?region=${aws.region}&secret-key=/etc/nix/${host-name}/secret&write-nar-listing=1&ls-compression=br&log-compression=br
        nar_buffer_size = ${let gb = 10; in toString (gb * 1024 * 1024 * 1024)}
        upload_logs_to_binary_cache = true
        log_prefix = https://${store-bucket}.s3.amazonaws.com/
      '';
      # TODO
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
      dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
    };
  };
}