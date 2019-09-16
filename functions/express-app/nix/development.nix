{
  tag ? "",
  pkgs ? (import ../../../nix {
    inputs.docker.tag = 
      pkgs.lib.last 
        (pkgs.lib.splitString ":" tag);
  })
}:
let
  modules = pkgs.project-config.modules;
  docker = modules.docker.express-app;
  yaml = modules.kubernetes.express-app.yaml.objects;
  package = modules.packages.express-app;
in
rec {
  inherit docker yaml package;
}