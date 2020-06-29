{ 
  sources ? import ./sources.nix,
  pkgs ? import <nixpkgs> {},
  system ? null,
  inputs ? {}
}:
let

  passthrough = self: super: rec {
    make-defaults = super.callPackage ./targets/defaults.nix {};
    rootFolder = toString ../.;

    project-config = 
      let
        safe-inputs = make-defaults inputs; 
      in
      (super.integration-modules.eval {
        modules = 
            (if pkgs.lib.isFunction safe-inputs.modules 
              then (safe-inputs.modules super) 
              else safe-inputs.modules)
          ++ [(./perspective + "/${safe-inputs.environment.perspective}")]
          ++ [(toString (./targets/modules + "/${safe-inputs.kubernetes.target}"))]
          ++ [./targets/environment-setup.nix];
        args = { 
          inputs = safe-inputs; 
          pkgs = super.pkgs;
          kubenix = super.kubenix;
          k8s-resources = k8s-resources;
        };
      }).config;

    inherit inputs;
  };

  overlays = [
    (import ./overlays/modules.nix {inherit sources;})
    (import ./overlays/overridings.nix {inherit sources;})
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
  import ./nixpkgs { inherit sources; extraArgs = args; }
