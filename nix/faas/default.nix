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

  # function-images = 
  #   lib.foldl
  #     lib.concatLists
  #     (builtins.map (x: x.images) (builtins.attrValues functions))
  #     [];
in
  functions
# rec {
#   inherit function-images;
#   inherit functions;
# }