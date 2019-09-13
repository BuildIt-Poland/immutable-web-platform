{
  environment ? null,
  kubernetes ? null,
  opa ? null,
  brigade ? null,
  docker ? null,
  aws ? null,
  tests ? null
}@inputs:
let
  pkgs = (import ./nix { inherit inputs; }).pkgs;
in
with pkgs;
  mkShell ({
    NIX_SHELL_NAME = "#core-shell";
    buildInputs = project-config.packages;
    shellHook= project-config.shellHook;
  } // project-config.environment.vars)