{system ? "x86_64-linux", ...}:
let
  pkgs = (import ../../../nix { 
    inherit system;
  });

  nixpkgs_path = pkgs.sources.nixpkgs.outPath;

  myOS = import "${nixpkgs_path}/nixos" {
    inherit system;

    configuration = {
     imports = [
        <nixpkgs/nixos/maintainers/scripts/ec2/amazon-image.nix>
        <nixpkgs/nixos/modules/profiles/minimal.nix>
        <nixpkgs/nixos/modules/profiles/headless.nix>
        ./configuration.nix
     ];

    config = {
      nix.nixPath = [ "nixpkgs=${nixpkgs_path}" ];
      nix.package = pkgs.nixUnstable;

      networking.firewall.allowedTCPPorts = [ 
        22
      ];
    };
  };
  };
in
  myOS