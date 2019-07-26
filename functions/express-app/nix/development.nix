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
{
  docker = pkgs.lib.head express-app.images;
  yaml = express-app.yaml;
}