{ src ? ./., ... }: 
let 
  pkgs = (import src { inputs = {
    environment = {
      type = "dev"; 
      perspective = "release";
    };
  }; }).pkgs;

  tools = 
    pkgs.lib.attrVals
      (builtins.attrNames 
        (pkgs.lib.filterAttrs (n: v: v == "directory")
          (builtins.readDir ./tools)))
      pkgs;
in 
  tools

  # TODO docker images