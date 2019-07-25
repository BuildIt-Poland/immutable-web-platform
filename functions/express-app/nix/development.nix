{
  hash ? "",
  pkgs ? (import ../../../nix {
    # ugly as **** - fix this
    hash = builtins.elemAt (builtins.tail (builtins.split ":" hash)) 1;
  })
}:
let
  express-app = pkgs.application.functions.express-app;
in
{
  docker = builtins.elemAt express-app.images 0;
  yaml = express-app.yaml;
}