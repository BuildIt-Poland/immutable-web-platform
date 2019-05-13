{ sources ? import ./sources.nix }:
let
  tools = self: super: {
    kubenix = super.callPackage sources.kubenix {};
  };
  config = self: super: {
    config = {
      env = "dev";
    };
  };
in
import sources.nixpkgs {
  overlays = [
    tools
    config
    (import ./deployment.nix)
  ];
}