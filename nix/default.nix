{ 
  sources ? import ./sources.nix,
  brigadeSharedSecret,
  env ? "dev"
}:
let
  rootFolder = ../.;

  tools = self: super: rec {
    kubenix = super.callPackage sources.kubenix {};
    knctl = super.callPackage ./tools/knctl.nix {};
    brigade = super.callPackage ./tools/brigade.nix {};
    yarn2nix = super.callPackage sources.yarn2nix {};
    k8s-local = super.callPackage ./k8s-local.nix {};
    find-files-in-folder = (super.callPackage ./find-files-in-folder.nix {}) rootFolder;
    cluster-stack = super.callPackage ./cluster-stack {};
    node-development-tools = super.callPackage ../development-tools {};
    chart-from-git = super.callPackage ./helm {};
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

  kubenix-modules = self: super: rec {
    kubenix-modules = [
      ./modules/knative-serve.nix
    ];
  };

  config = self: super: rec {
    env-config = rec {
      inherit rootFolder env;

      knative-serve = import ./modules/knative-serve.nix;
      projectName = "future-is-comming";
      version = "0.0.1";
      ports = {
        istio-ingress = "32632";
      };

      kubernetes = {
        version = "1.13";
        namespace = {
          functions = "default";
          infra = "local-infra";
        };
      };

      is-dev = env == "dev";

      brigade = {
        sharedSecret = brigadeSharedSecret;
      };

      helm = {
        home = "${builtins.toPath env-config.rootFolder}/.helm";
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
  args = { } // { inherit overlays; };
in
  import sources.nixpkgs args