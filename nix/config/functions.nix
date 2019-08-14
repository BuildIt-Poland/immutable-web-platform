{pkgs}:
with pkgs;
let
  function-packages = 
    lib.findFilesInFolder 
      ./../..
      "/functions" 
      "/nix/default.nix";

  functions = 
    builtins.mapAttrs 
      (x: y: import y) 
      function-packages;
in
  functions