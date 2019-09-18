{ src ? ./., supportedSystems ? ["x86_64-linux"], ... }: 
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
    source = v;

    tarball = pkgs.releaseTools.sourceTarball {
      name = "${v.name}-tarball";
      src = v;
    };

    build =  pkgs.lib.genAttrs supportedSystems (system:
      let
        pkgs = (import src { 
          inherit system;

          inputs = {
            environment = {
              type = "dev"; 
              perspective = "release";
            }; 
          }; 
        }).pkgs;
      in
        pkgs.releaseTools.nixBuild {
          name = v.name;
          src = tarball;
        });

  }) tools;
  
  charts = pkgs.k8s-resources;
in 
  # (tools-release // charts)
  tools-release

  # TODO docker images