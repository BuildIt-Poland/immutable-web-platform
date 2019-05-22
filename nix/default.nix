{ 
  sources ? import ./sources.nix,
  use-docker ? false,
  fresh ? false,
  env ? "dev"
}:
let
  pkgsOpts = 
    if use-docker
      then { system = "x86_64-linux"; }
      else {};

  rootFolder = ../.;

  tools = self: super: rec {
    kubenix = super.callPackage sources.kubenix {};
    yarn2nix = super.callPackage sources.yarn2nix {};
    k8s-local = super.callPackage ./k8s-local.nix {};
    find-files-in-folder = (super.callPackage ./find-files-in-folder.nix {}) rootFolder;
    cluster-stack = super.callPackage ./cluster-stack {};
  };

  external = self: super: rec {
    kind = super.callPackage ./tools/kind.nix {};
  };
  
  config = self: super: rec {
    env-config = rec {
      inherit rootFolder env;

      projectName = "future-is-comming";
      version = "0.0.1";

      kubeconfigPath = 
        if env == "dev" 
          then "$KUBECONFIG" 
          else "kind-config-$KUBECONFIG";

      helmHome = "${builtins.toPath env-config.rootFolder}/.helm";

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
    external
    (import ./functions.nix)
  ];
  args = { } // pkgsOpts // { inherit overlays; };
in
  import sources.nixpkgs args