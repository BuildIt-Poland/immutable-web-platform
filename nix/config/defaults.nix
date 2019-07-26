{pkgs, lib}:
with pkgs; 
  input:  
    lib.recursiveUpdate {
      kubernetes = { clean = false; update = false; save = true; };
      docker = { upload = false; tag = ""; };
      brigade = { secret = ""; };
      aws = { region = ""; };
    } input