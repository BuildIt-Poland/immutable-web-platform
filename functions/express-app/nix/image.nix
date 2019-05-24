{ pkgs, env-config, callPackage }:
let
  express-app = callPackage ./package.nix { };
  fn-config = callPackage ./config.nix {};

  # as we are pusing to kind local cluster we don't want to create new image each time
  is-local = env-config.is-dev;
  local-development = 
    if is-local
      then { tag = "latest"; } 
      else {};
in
pkgs.dockerTools.buildLayeredImage ({
  name = if is-local 
    then "dev.local/${fn-config.label}"
    else fn-config.label;

  contents = [ 
    pkgs.nodejs 
    pkgs.bash
    express-app # application
  ];

  extraCommands = ''
    mkdir etc
    chmod u+w etc
  '';

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = ["start-server"];
    WorkingDir = "${express-app}";
    ExposedPorts = {
      "${toString fn-config.port}/tcp" = {};
    };
  };
}  // local-development)