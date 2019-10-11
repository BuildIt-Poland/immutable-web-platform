{ system ? "x86_64-linux"
, preload ? false
, ...
}:
  (import ../default.nix { 
    inherit system;

    inputs = {
      environment = {
        type = "dev"; 
        perspective = "builder";

        inherit preload;
      };
    };
  })