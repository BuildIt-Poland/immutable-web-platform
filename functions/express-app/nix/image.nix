{ pkgs, env-config }:
pkgs.dockerTools.buildLayeredImage {
  name = "express-knative-example-app";

  contents = [ pkgs.nodejs ];

  runAsRoot = ''
    npm install --only=production
  '';

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = ["npm" "start"];
    ExposedPorts = {
      "80/tcp" = {};
    };
  };
}