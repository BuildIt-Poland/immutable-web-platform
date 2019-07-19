{ 
  sources ? import ./sources.nix,
  brigadeSharedSecret ? "", # it would be good to display warning related to that
  env ? "dev", # TODO env should be more descriptive, sth like { target: "ec2|local", env: "dev|prod", experimental: "true|false" }
  region ? null,
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
    find-files-in-folder = (super.callPackage ./helpers/find-files-in-folder.nix {}) rootFolder;
    log = super.callPackage ./helpers/log.nix {};
    yaml-to-json = super.callPackage ./helpers/yaml-to-json.nix {};

    # Brigade
    brigade = super.callPackage ./tools/brigade.nix {};
    brigadeterm = super.callPackage ./tools/brigadeterm.nix {};

    # K8S
    kubenix = super.callPackage sources.kubenix {};
    knctl = super.callPackage ./tools/knctl.nix {}; # knative
    kubectl-repl = super.callPackage ./tools/kubectl-repl.nix {}; 
    hey = super.callPackage ./tools/hey.nix {}; 
    istioctl = super.callPackage ./tools/istioctl.nix {}; 
    chart-from-git = super.callPackage ./helm {};
    k8s-local = super.callPackage ./k8s-local.nix {};

    # NodeJS packages
    yarn2nix = super.callPackage sources.yarn2nix {};
    node-development-tools = super.callPackage "${nodePackages}/development-tools/nix" {};
    brigade-extension = super.callPackage "${nodePackages}/brigade-extension/nix" {};
    remote-state = super.callPackage "${nodePackages}/remote-state/nix" {};

    # gitops
    # THIS is correct way however need some final touches to make this right
    # argocd = super.callPackage ./gitops/argocd {};
    argocd = super.callPackage ./tools/argocd.nix {};
  };

  # this part is soooo insane! don't know if it is valid ... but works o.O
  # building on darwin in linux in one run
  application = self: super: rec {
    linux-pkgs = 
      import sources.nixpkgs ({ 
        system = "x86_64-linux"; 
      } // { inherit overlays; });

    remote-worker = super.callPackage ./remote-worker {};
    application = super.callPackage ./functions.nix {};
    cluster = super.callPackage ./cluster-stack {};
    charts = super.callPackage ./cluster-stack/charts.nix {};
    k8s-cluster-operations = super.callPackage ./cluster-stack/k8s-cluster-operations.nix {};
    modules = super.callPackage ./modules {};
    inherit sources;
  };

  kubenix-modules = self: super: rec {
    kubenix-modules = [
      ./kubenix-modules/knative-serve.nix
    ];
    kubenix-infra-modules = [
      ./kubenix-modules/virtual-services.nix
      ./kubenix-modules/brigade.nix
    ];
  };

  config = self: super: rec {
    env-config = super.callPackage ./config.nix {

      aws-profiles = super.callPackage ./helpers/get-aws-credentials.nix {};

      inherit 
        brigadeSharedSecret 
        rootFolder 
        region
        env;
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