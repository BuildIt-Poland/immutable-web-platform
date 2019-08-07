{
  local ? false
}:
let
  pkgs = (import ../nix { 
    inputs = {
      environment.type = "brigade"; 
      tests.enable = false;
      kubernetes = {
        save = false;
        patches = false;
      };

      modules = [
        pkgs.shell-modules.modules.bitbucket-k8s-repo
        ({
          bitbucket.k8s-resources.repository = "k8s-infra-descriptors";
        })
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

  # FIXME add module to RUN TESTS from module!
  buildInputs = project-config.packages;
  shellHook= project-config.shellHook;
}