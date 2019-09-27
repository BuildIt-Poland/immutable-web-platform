# FIXME add optional pkgs
{...}@inputs:
let
  pkgs = (import ./. { inherit inputs; }).pkgs;
  name = "#shell#${pkgs.project-config.environment.perspective}";
in
with pkgs;
  mkShell ({
    NIX_SHELL_NAME = name;
    buildInputs = project-config.packages;
    shellHook= project-config.shellHook;
  } // project-config.environment.vars)