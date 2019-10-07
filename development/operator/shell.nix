{...}:
let
  inputs = {
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
  };
in
  import ../../nix/run-shell.nix inputs