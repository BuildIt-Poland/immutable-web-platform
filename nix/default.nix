{ 
  sources ? import ./sources.nix,
  system ? null,
  inputs,
  project-config 
}:
let
  rootFolder = ../.;

  passthrough = self: super: rec {
    inherit project-config;
    gitignore = super.nix-gitignore.gitignoreSourcePure [ ".gitignore" ];
  };

  # this part is soooo insane! don't know if it is valid ... but works o.O
  # building on darwin in linux in one run
  application = self: super: rec {
    linux-pkgs = 
      import sources.nixpkgs ({ 
        system = "x86_64-linux"; 
      } // { inherit overlays; });

    # application = super.callPackage ./functions.nix {};
    cluster = super.callPackage ./cluster-stack {};

    k8s-resources = super.callPackage ./k8s-resources {};
    k8s-operations = super.callPackage ./k8s-operations {};

    inherit sources;
  };

  overlays = [
    (import ./overlays/overridings.nix {inherit sources;})
    passthrough
    (import ./overlays/tools.nix {inherit sources;})
    (import ./overlays/kubenix.nix {inherit sources;})
    (import ./overlays/shell-modules.nix {inherit sources;})
    # config
    application
  ];
  args = 
    { } 
    // { inherit overlays; } 
    // (if system != null then { inherit system; } else {});
in
  import sources.nixpkgs args