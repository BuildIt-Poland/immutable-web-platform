{ src ? ./., ... }: 
let 
  pkgs = (import src { inputs = {
    environment = {
      type = "dev"; 
      perspective = "release";
    };
  }; }).pkgs;

  tools = 
    let
      folders = 
        (builtins.attrNames 
          (pkgs.lib.filterAttrs (n: v: v == "directory")
            (builtins.readDir ./tools)));
    in
      pkgs.lib.foldl 
        (x: y: (pkgs.lib.recursiveUpdate x {"${y}" = (builtins.getAttr y pkgs);}))
        {}
        folders;
in 
  tools

  # TODO docker images