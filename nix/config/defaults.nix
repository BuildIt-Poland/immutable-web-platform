{pkgs, lib}:
with pkgs; 
  input:  
    lib.recursiveUpdate {
      environment = { type = "local"; };
      kubernetes = { target="eks"; clean = false; update = false; save = false; patches = false; };
      docker = { upload = false; tag = "dev-build"; };
      brigade = { secret = ""; };
      aws = { region = ""; };
      tests = {enable = false;};
      modules = [];
    } input