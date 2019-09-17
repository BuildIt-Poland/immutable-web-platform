{system ? "x86_64-linux", ...}:
let
  pkgs = (import ../../nix { 
    inherit system;

    inputs = {
      environment = {
        type = "dev"; 
        perspective = "builder";
      };
    };
  });

  nixpkgs_path = pkgs.sources.nixpkgs;
  hydra_path = pkgs.sources.hydra;
in
  import "${nixpkgs_path}/nixos" {
    inherit system;

    configuration = {
      imports = [
        ./ec2-nixos.nix
        ./shell.nix
        ./copy-source.nix
        ./modules/hydra/master.nix
        (import "${hydra_path}/hydra-module.nix")
      ];

      config = {
        nixpkgs.pkgs = pkgs;
        nix = {
          gc.automatic = true;
          autoOptimiseStore = true;

          binaryCaches = [ "https://cache.nixos.org" ];
          binaryCachePublicKeys = [];
        };

        networking.firewall.allowedTCPPorts = [ 
          22
          80
        ];

        # services.hydra.workers = [{ 
        #   hostName = "slave1"; 
        #   maxJobs = 1; 
        #   speedFactor = 1; 
        #   sshKey = "/etc/nix/id_buildfarm"; 
        #   sshUser = "root"; 
        #   system = "x86_64-linux"; 
        # }]

        # environment.etc = pkgs.lib.singleton {
        #   target = "nix/id_buildfarm";
        #   source = ./id_buildfarm;
        #   uid = config.ids.uids.hydra;
        #   gid = config.ids.gids.hydra;
        #   mode = "0440";
        # };
      };
    };
  }