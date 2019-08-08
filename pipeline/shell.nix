{
  local ? false
}:
let
  pkgs = (import ../nix { 
    # system = "x86_64-linux";

    inputs = {
      environment.type = "brigade"; 
      tests.enable = false;
      kubernetes = {
        save = false;
        patches = false;
      };

      modules = [
        {
          bitbucket.k8s-resources = {
            enable = true;
            repository = "k8s-infra-descriptors";
          };
        }
      ];
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