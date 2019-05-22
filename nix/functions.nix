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

    build-and-push-local = writeScriptBin "build-and-push-local"
      (lib.concatMapStrings 
        (docker-image: ''
          echo "Pushing docker image to local cluster"
          ${kind}/bin/kind load image-archive --name ${env-config.projectName} ${docker-image}
        '') (lib.flatten function-images));
  };
in
rec {
  inherit function-images;
  functions = 
    functionsMap 
    // { inherit scripts; }
    ;
}