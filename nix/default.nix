{ 
  sources ? import ./sources.nix,
  use-docker ? false
}:
let
  pkgsOpts = 
    if use-docker
      then { system = "x86_64-linux"; }
      else {};

  tools = self: super: {
    kubenix = super.callPackage sources.kubenix {};
    yarn2nix = super.callPackage sources.yarn2nix {};
    # arion = super.callPackage ((import sources.arion {}).arion) {};
    arion = (sources.arion.arion {});
    find-files-in-folder = (super.callPackage ./find-files-in-folder.nix {}) ../.;
  };

  config = self: super: {
    env-config = {
      env = "dev";
      helm = {
        namespace = "local-infra";
      };
      docker = {
        registry = "docker.io/gatehub";
        destination = "docker://damianbaar"; # skopeo path transport://repo
      };
    };
  };

  overlays = [
    tools
    config
    (import ./deployment.nix)
  ];
  args = { } // pkgsOpts // { inherit overlays; };
in
  import sources.nixpkgs args