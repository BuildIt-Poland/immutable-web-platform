{pkgs, lib}:
with pkgs; 
  input:  
    let
      result = (lib.recursiveUpdate {
        environment = { type = "dev"; perspective = "root"; };
        kubernetes = { 
          target="eks"; 
          clean = false; 
          update = false; 
          save = false; 
          patches = false; 
          tools = false;
        };
        opa = { validation = false; };
        docker = { upload = false; tag = "dev-build"; };
        project = { name = "future-is-comming"; };
        brigade = { secret = ""; };
        aws = { region = ""; };
        tests = {enable = false;};
        modules = [(toString (./modules + "/${result.kubernetes.target}"))];
      } input);
    in result