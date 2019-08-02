{pkgs, lib}:
with pkgs; 
  input:  
    lib.recursiveUpdate {
      environment = { type = "local"; };
      kubernetes = { clean = false; update = false; save = true; };
      docker = { upload = false; tag = "dev-build"; };
      brigade = { secret = ""; };
      aws = { region = ""; };
    } input