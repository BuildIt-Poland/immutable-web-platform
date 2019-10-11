# need to find a way to build amazon ami on darwin with nix
{ system ? "x86_64-linux"
, preload ? false
, pkgs ? (import ./nixpkgs.nix { inherit preload system; })
, ...
}:
let
  nixpkgs_path = pkgs.sources.nixpkgs;
  hydra_path = pkgs.sources.hydra;

  project = pkgs.project-config.project;
  host-name = project.make-sub-domain "hydra";
in
{
  imports = (builtins.filter (x: x != "") [
    ./modules/ec2-nixos.nix
    ./modules/base.nix
    ./modules/copy-source.nix
    ./modules/proxy.nix
    ./modules/nix-serve.nix
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
  };
}