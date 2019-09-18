{ src ? ./., ... }: 
let 
  pkgs = (import src { inputs = {
    environment = {
      type = "dev"; 
      perspective = "release";
    };
  }; }).pkgs;

  tools = 
    (builtins.attrNames 
      (lib.filterAttrs (n: v: v == "directory")
        (builtins.readDir ./tools)));
in 
{
  hello = pkgs.hello;
} // (lib.attrVals tools pkgs);