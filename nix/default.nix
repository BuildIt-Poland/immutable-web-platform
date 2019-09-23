{ 
  sources ? import ./sources.nix,
  system ? null,
  inputs ? {}
}:
let

  passthrough = self: super: rec {
    gitignore = super.nix-gitignore.gitignoreSourcePure [ ".gitignore" ];
    make-defaults = super.callPackage ./targets/defaults.nix {};
    rootFolder = toString ../.;

    # this part is soooo insane! don't know if it is valid ... but works o.O
    # building on darwin in linux in one run
    linux-pkgs = 
      import sources.nixpkgs ({ 
        system = "x86_64-linux"; 
      } // { inherit overlays; });

    k8s-resources = super.callPackage ./k8s-resources {};

    project-config = 
      let
        safe-inputs = make-defaults inputs; 
      in
      (super.integration-modules.eval {
        modules = 
             [(./targets/perspective + "/${safe-inputs.environment.perspective}")]
          ++ safe-inputs.modules 
          ++ [./targets/environment-setup.nix];
        args = { 
          inputs = safe-inputs; 
          pkgs = super.pkgs;
          kubenix = super.kubenix;
          k8s-resources = k8s-resources;
        };
      }).config;

    inherit sources;
    inherit inputs;
  };

  nix-tests = self: super: rec {
    nix-test = super.callPackage ./testing.nix {};
  };

  nixos-image = self: super: rec {
    nixos-hydra = import ./nixos/hydra-config.nix;
  };

  application = self: super: rec {
    k8s-operations = super.callPackage ./k8s-operations {};
  };

  overlays = [
    (import ./overlays/modules.nix {inherit sources;})
    (import ./tools {inherit sources;})
    (import ./lib {inherit sources;})
    passthrough
    application
    nix-tests
  ];
  args = 
    { } 
    // { inherit overlays; } 
    // (if system != null then { inherit system; } else {});
in
  import ./nixpkgs { inherit sources args; }