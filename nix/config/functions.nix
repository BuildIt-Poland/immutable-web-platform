{pkgs}:
with pkgs;
let
  function-packages = 
    find-files-in-folder 
      "/functions" 
      "/nix/default.nix";

  functions = 
    builtins.mapAttrs 
      (x: y: import y) 
      function-packages;
in
  functions