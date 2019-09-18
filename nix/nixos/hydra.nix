# need to find a way to build amazon ami on darwin with nix
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

  project = pkgs.project-config.project;
  host-name = project.make-sub-domain "hydra";
in
  import "${nixpkgs_path}/nixos" {
    inherit system;

    configuration = {
      imports = [
        ./modules/ec2-nixos.nix
        ./modules/shell.nix
        ./modules/copy-source.nix
        ./modules/hydra/master.nix
        ./modules/nix-serve.nix
        (import "${hydra_path}/hydra-module.nix")
      ];

      config = {
        networking.hostName = host-name;

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

        services.hydra.debugServer = true;

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