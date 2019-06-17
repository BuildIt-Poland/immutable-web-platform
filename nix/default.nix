{ 
  sources ? import ./sources.nix,
  brigadeSharedSecret ? "", # it would be good to display warning related to that
  env ? "dev",
  system ? null
}:
let
  rootFolder = ../.;
  nodePackages = "${rootFolder}/packages";

  overridings = self: super: rec {
    # INFO recent update of kind in nixpgs does not work on darwin
    # INFO version 0.3.0 returns invalid tar.gz header
    kind = (super.callPackage ./tools/kind.nix {});
  };

  tools = self: super: rec {
    # Terraform
    terraform-with-plugins = super.callPackage ./terraform {};

    # Helpers
    find-files-in-folder = (super.callPackage ./find-files-in-folder.nix {}) rootFolder;
    log = super.callPackage ./helpers/log.nix {};

    # Brigade
    brigade = super.callPackage ./tools/brigade.nix {};
    brigadeterm = super.callPackage ./tools/brigadeterm.nix {};

    # K8S

    kubenix = super.callPackage sources.kubenix {};
    knctl = super.callPackage ./tools/knctl.nix {}; # knative
    kubectl-repl = super.callPackage ./tools/kubectl-repl.nix {}; # 
    chart-from-git = super.callPackage ./helm {};
    k8s-local = super.callPackage ./k8s-local.nix {};
    k8s-cluster-operations = super.callPackage ./cluster-stack/k8s-cluster-operations.nix {};

    # NodeJS packages
    yarn2nix = super.callPackage sources.yarn2nix {};
    node-development-tools = super.callPackage "${nodePackages}/development-tools/nix" {};
    brigade-extension = super.callPackage "${nodePackages}/brigade-extension/nix" {};
    remote-state = super.callPackage "${nodePackages}/remote-state/nix" {};
  };

  # this part is soooo insane! don't know if it is valid ... but works o.O
  # building on darwin in linux in one run
  application = self: super: rec {
    linux-pkgs = 
      if builtins.currentSystem == "x86_64-darwin"
        then (import sources.nixpkgs ({ 
          system = "x86_64-linux"; 
        } // { inherit overlays; }))
        else super.pkgs;

    remote-worker = super.callPackage ./remote-worker {};
    application = super.callPackage ./functions.nix {};
    cluster = super.callPackage ./cluster-stack {};
    inherit sources;
  };

  kubenix-modules = self: super: rec {
    kubenix-modules = [
      ./modules/knative-serve.nix
    ];
  };

  config = self: super: rec {
    env-config = super.callPackage ./config.nix {

      aws-profiles = super.callPackage ./get-aws-credentials.nix {};

      inherit brigadeSharedSecret;
      inherit rootFolder;
      inherit env;
    };
  };

  overlays = [
    overridings
    tools
    config
    kubenix-modules
    application
  ];
  args = 
    { } 
    // { inherit overlays; } 
    // (if system != null then { inherit system; } else {});
in
  import sources.nixpkgs args