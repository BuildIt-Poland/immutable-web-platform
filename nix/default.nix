{ sources ? import ./sources.nix }:
let
  tools = self: super: {
    kubenix = super.callPackage sources.kubenix {};
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