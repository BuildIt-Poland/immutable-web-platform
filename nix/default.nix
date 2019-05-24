{ 
  sources ? import ./sources.nix,
  use-docker ? false,
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

  kubenix-modules = self: super: rec {
    modules = {
      knative-serve = import ./modules/knative-serve.nix;
    };
  };

  # this part is soooo insane! don't know if it is valid ... but works o.O
  # building on darwin in linux in one run
  application = self: super: rec {
    application = super.callPackage ./functions.nix {
      pkgs = import sources.nixpkgs ({
        system = "x86_64-linux";
      } // { inherit overlays; });
    };
  };

  config = self: super: rec {
    env-config = rec {
      inherit rootFolder env;

      knative-serve = import ./modules/knative-serve.nix;
      projectName = "future-is-comming";
      version = "0.0.1";

      kubernetes = {
        version = "1.13";
      };

      is-dev = env == "dev";

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
    kubenix-modules
    application
  ];
  args = { } // pkgsOpts // { inherit overlays; };
in
  import sources.nixpkgs args