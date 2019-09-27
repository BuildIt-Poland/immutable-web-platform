{...}:
let
  pkgs = (import ../../nix { inputs = {
    kubernetes = {
      target = "eks";
      clean = false;
      save = true;
      update = false;
    };
    environment = {
      perspective = "operator";
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