{ pkgs, env-config }:
let
  express-app = pkgs.callPackage ./package.nix { };
in
pkgs.dockerTools.buildLayeredImage {
  name = "express-knative-example-app";

  contents = [ pkgs.nodejs express-app pkgs.bash];

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = ["npm" "start"];
    ExposedPorts = {
      "80/tcp" = {};
    };
  };
}