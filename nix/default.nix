{ sources ? import ./sources.nix }:
let
  tools = self: super: {
    kubenix = super.callPackage sources.kubenix {};
    yarn2nix = super.callPackage sources.yarn2nix {};
  };
  config = self: super: {
    env-config = {
      env = "dev";
      docker-registry = "docker.io/gatehub";
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