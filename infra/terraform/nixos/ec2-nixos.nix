{system ? "x86_64-linux", ...}:
let
  pkgs = (import ../../../nix { 
    inherit system;
  });

  myOS = import "${pkgs.sources.nixpkgs.outPath}/nixos" {
    inherit system;

    configuration = {
     imports = [
        <nixpkgs/nixos/maintainers/scripts/ec2/amazon-image.nix>
        <nixpkgs/nixos/modules/profiles/minimal.nix>
        <nixpkgs/nixos/modules/profiles/headless.nix>
        ./configuration.nix
     ];
    config = {
      networking.firewall.allowedTCPPorts = [ 
        22
      ];
    };
  };
  };
in
  myOS