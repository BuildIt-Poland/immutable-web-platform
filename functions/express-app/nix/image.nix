{ linux-pkgs, env-config, callPackage }:
let
  pkgs = linux-pkgs;
  express-app = callPackage ./package.nix {
    inherit pkgs;
   };
  fn-config = callPackage ./config.nix {};
in
pkgs.dockerTools.buildLayeredImage ({
  name = fn-config.docker-label;
  maxLayers = 120;

  contents = [ 
    pkgs.nodejs-slim-11_x
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