{ src ? ./., ... }: 
let 
  pkgs = (import src { inputs = {
    environment = {
      type = "dev"; 
      perspective = "release";
    };
  }; }).pkgs;

  tools = 
    with pkgs.lib;
    with builtins;
    let
      folders = 
        (attrNames 
          (filterAttrs (n: v: v == "directory")
            (readDir ./tools)));
    in
      foldl 
        (x: y: (recursiveUpdate x {"${y}" = (getAttr y pkgs);}))
        {}
        folders;

  tools-release = pkgs.lib.mapAttrs (n: v: rec {
    tarball = pkgs.releaseTools.sourceTarball {
      name = "${v.name}-tarball";
      src = v;
      buildInputs = (with pkgs; [ gettext texLive texinfo ]);
    };

    build = 
      { system ? builtins.currentSystem }:
        pkgs.releaseTools.nixBuild {
          name = v.name;
          src = tarball;
        };
  }) tools;
  
  charts = pkgs.k8s-resources;
in 
  (tools-release // charts)

  # TODO docker images