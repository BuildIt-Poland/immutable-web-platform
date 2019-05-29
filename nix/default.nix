{ 
  sources ? import ./sources.nix,
  brigadeSharedSecret ? "", # it would be good to display warning related to that
  env ? "dev"
}:
let
  rootFolder = ../.;

  tools = self: super: rec {
    kubenix = super.callPackage sources.kubenix {};
    knctl = super.callPackage ./tools/knctl.nix {};
    brigade = super.callPackage ./tools/brigade.nix {};
    brigadeterm = super.callPackage ./tools/brigadeterm.nix {};
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
    env-config = super.callPackage ./config.nix {

      aws-credentials = super.callPackage ./get-aws-credentials.nix {};

      inherit brigadeSharedSecret;
      inherit rootFolder;
      inherit env;
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