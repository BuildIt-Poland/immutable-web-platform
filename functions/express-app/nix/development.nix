{
  tag ? "",
  pkgs ? (import ../../../nix {
    inputs.docker.tag = 
      pkgs.lib.last 
        (pkgs.lib.splitString ":" tag);
  })
}:
let
  express-app = pkgs.application.functions.express-app;
in
rec {
  docker = pkgs.lib.head express-app.images;
  yaml = express-app.yaml;

  # just a test of alternative building
  image = 
    let
      dockerfile = pkgs.writeText "Dockerfile" ''
        FROM nginx
      '';
    in
      pkgs.kaniko-build {
        inherit dockerfile;
        imageName = "dev_local/express-app";
        src = [./.];
        # extraContent = "";
      };
}