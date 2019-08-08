{
  environment ? null,
  kubernetes ? null,
  brigade ? null,
  docker ? null,
  aws ? null,
  tests ? null
}@inputs:
let
  pkgs = (import ./nix { inherit inputs; }).pkgs;
in
with pkgs;
  mkShell {
    PROJECT_NAME = project-config.project.name;
    NIX_SHELL_NAME = "#core-shell";
    
    # FIXME move terraform to infra shell
    buildInputs = [pkgs.terraform-with-plugins] ++ project-config.packages;
    shellHook= project-config.shellHook;
  }