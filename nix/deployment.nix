self: super: 
with super;
let
  functionPackages = 
    find-files-in-folder 
      "/functions" 
      "nix/default.nix";

  functionsMap = 
    builtins.mapAttrs 
      (x: y: callPackage y {}) 
      functionPackages;

  function-images = 
    lib.foldl
      lib.concatLists
      (builtins.map (x: x.images) (builtins.attrValues functionsMap))
      [];

  scripts = { 
    build-and-push = writeScriptBin "build-and-push" 
      (lib.concatMapStrings 
        (docker-images: ''
          ${kubenix.lib.docker.copyDockerImages { 
            images = docker-images; 
            dest = env-config.docker.destination;
          }}/bin/copy-docker-images
        '') function-images);
  };
in
rec {
  functions = 
    functionsMap 
    // { inherit scripts; }
    ;
}