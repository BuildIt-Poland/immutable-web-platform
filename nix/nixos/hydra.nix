# need to find a way to build amazon ami on darwin with nix
{ system ? "x86_64-linux"
, preload ? false
, pkgs ? (import ./nixpkgs.nix { inherit preload system; })
, ...
}:
  import "${pkgs.sources.nixpkgs}/nixos" {
    inherit system;

    configuration = {
      imports = [
        (import ./hydra-config.nix { 
          inherit preload pkgs system;
        })
      ];
    };
  }