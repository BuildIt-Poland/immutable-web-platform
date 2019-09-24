{...}:
let
  pkgs = (import ../../nix { inputs = {
    kubernetes = {
      target = "minikube";
      clean = false;
      save = true;
      update = false;
    };
    environment = {
      perspective = "lorri";
    };
    docker = {
      upload = false;
    };
    opa = {
      validation = false;
    };
  }; }).pkgs;
in
with pkgs;
  mkShell ({
    NIX_SHELL_NAME = "#minikube#${pkgs.project-config.environment.perspective}";
    buildInputs = project-config.packages;
    shellHook= project-config.shellHook;
  } // project-config.environment.vars)