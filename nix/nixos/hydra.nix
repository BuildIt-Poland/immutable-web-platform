# need to find a way to build amazon ami on darwin with nix
{system ? "x86_64-linux", preload ? false, ...}:
let
  pkgs = (import ../../nix { 
    inherit system;

    inputs = {
      environment = {
        type = "dev"; 
        perspective = "builder";
        inherit preload;
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
      imports = (builtins.filter (x: x != "") [
        ./modules/ec2-nixos.nix
        ./modules/shell.nix
        ./modules/copy-source.nix
        (import "${hydra_path}/hydra-module.nix")
        (if !preload then ./modules/hydra/master.nix else "")
      ]);

      config = {
        networking.hostName = host-name;

        nixpkgs.pkgs = pkgs;
        nix = {
          nixPath = [ "nixpkgs=${nixpkgs_path}" ];

          useSandbox = true; # relaxed
          gc.automatic = true;
          autoOptimiseStore = true;

          binaryCaches = [ 
            "https://cache.nixos.org" 
          ];

          trustedBinaryCaches = [
            "s3://${pkgs.project-config.aws.s3-buckets.worker-cache}?region=${pkgs.project-config.aws.region}"
          ];

          binaryCachePublicKeys = [];
        };

        networking.firewall.allowedTCPPorts = [ 
          22
          80
        ];
      };
    };
  }