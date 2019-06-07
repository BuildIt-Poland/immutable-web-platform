{ linux-pkgs, env-config, callPackage }:
let
  pkgs = linux-pkgs;
  express-app = callPackage ./package.nix {
    inherit pkgs;
   };
  fn-config = callPackage ./config.nix {};

  # as we are pusing to kind local cluster we don't want to create new image each time
  # TODO take from env-config -> and use other tag than latest to avoid imagePullPolicy to Always
in
pkgs.dockerTools.buildLayeredImage ({
  name = 
    if env-config.is-dev
      then fn-config.image-name-for-docker-when-dev
      else fn-config.label;

  contents = [ 
    pkgs.nodejs-slim-11_x
    pkgs.bash
    pkgs.coreutils
    express-app # application
  ];

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = ["start-server"];
    WorkingDir = "${express-app}";
    ExposedPorts = {
      "${toString fn-config.port}/tcp" = {};
    };
  };
} // env-config.docker.tag)