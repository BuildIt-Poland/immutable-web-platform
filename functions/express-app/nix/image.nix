{ pkgs, env-config }:
let
  express-app = pkgs.callPackage ./package.nix { };
in
pkgs.dockerTools.buildLayeredImage {
  name = "express-knative-example-app";
  tag = "latest"; # this should be env sensitive

  contents = [ pkgs.nodejs express-app pkgs.bash];

  extraCommands = ''
    mkdir etc
    chmod u+w etc
  '';

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = ["start-server"];
    ExposedPorts = {
      "80/tcp" = {};
    };
  };
}