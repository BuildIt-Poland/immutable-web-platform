{ 
  sources ? import ./sources.nix,
  system ? null,
  inputs ? {}
}:
let

  passthrough = self: super: rec {
    gitignore = super.nix-gitignore.gitignoreSourcePure [ ".gitignore" ];
    make-defaults = super.callPackage ./config/defaults.nix {};
    rootFolder = toString ../.;

    # this part is soooo insane! don't know if it is valid ... but works o.O
    # building on darwin in linux in one run
    linux-pkgs = 
      import sources.nixpkgs ({ 
        system = "x86_64-linux"; 
      } // { inherit overlays; });

    project-config = (super.shell-modules.eval {
      modules = [./config/local-env.nix]; # this should be injected from external
      args = { 
        inputs = make-defaults inputs; 
        pkgs = super.pkgs;
      };
    }).config;

    inherit sources;
    inherit inputs;
  };

  nix-tests = self: super: rec {
    nix-test = super.callPackage ./testing.nix {};
  };

  application = self: super: rec {

    application = super.callPackage ./faas {};
    cluster = super.callPackage ./cluster-stack {};

    k8s-resources = super.callPackage ./k8s-resources {};
    k8s-operations = super.callPackage ./k8s-operations {};
  };

  overlays = [
    (import ./overlays/overridings.nix {inherit sources;})
    (import ./overlays/tools.nix {inherit sources;})
    (import ./overlays/kubenix.nix {inherit sources;})
    (import ./overlays/shell-modules.nix {inherit sources;})
    passthrough
    application
    nix-tests
  ];
  args = 
    { } 
    // { inherit overlays; } 
    // (if system != null then { inherit system; } else {});
in
  import sources.nixpkgs args