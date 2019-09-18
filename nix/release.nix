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

  tools-release = pkgs.lib.mapAttrs (n: v:
    (pkgs.lib.genAttrs supportedSystems (system:
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
      in rec {
        build = (builtins.getAttr n pkgs);
        tarball = pkgs.releaseTools.binaryTarball {
          name = "${build.name}-tarball";
          src = build;
          installPhase = ''
            mkdir -p $out/bin
            cp $src/bin/${n} $out/bin/${n}
          '';
        };
      }
    ))
  ) tools;
  
  charts-release = 
    pkgs.lib.filterAttrs 
      (n: v: !(pkgs.lib.isFunction v)) 
      pkgs.k8s-resources;
in 
  (tools-release // charts-release)

  # TODO docker images