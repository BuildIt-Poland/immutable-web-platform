{
  environment ? null,
  kubernetes ? null,
  brigade ? null,
  docker ? null,
  aws ? null
}@inputs:
let
  pkgs = (import ./nix { inherit inputs; }).pkgs;
in
with pkgs;
  mkShell {
    PROJECT_NAME = project-config.project.name;

    buildInputs = [pkgs.terraform-with-plugins] ++ project-config.packages;
    shellHook= project-config.shellHook;
  }