{ src ? ./., ... }: 
let 
  pkgs = (import src { inputs = {
    environment = {
      type = "dev"; 
      perspective = "release";
    };
  }; }).pkgs;

  tools = 
    lib.attrVals
      (builtins.attrNames 
        (lib.filterAttrs (n: v: v == "directory")
          (builtins.readDir ./tools)))
      pkgs;
in 
  tools