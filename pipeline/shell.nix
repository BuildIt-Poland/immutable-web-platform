{
  local ? false
  target ? "eks"
}:
let
  pkgs = (import ../nix { 
    inputs = {
      environment = {
        type = "dev"; 
        perspective = "builder";
      };
      kubernetes = {
        inherit target;

        save = false;
        patches = false;
      };
    };
  });
in
with pkgs; 
mkShell {
  NIX_SHELL_NAME = "#brigade-pipeline";

  BUILD_ID =
    if local 
      then "local-build-${pkgs.project-config.project.hash}"
      else null;

  SECRETS = 
    if local 
      then (builtins.readFile ../secrets.json) 
      else null;

  PROJECT_NAME = project-config.project.name;
  buildInputs = project-config.binary-store-cache;
  shellHook = project-config.shellHook;
}