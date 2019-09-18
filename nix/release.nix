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
  
  charts = pkgs.k8s-resources;
in 
  (tools // charts)

  # TODO docker images