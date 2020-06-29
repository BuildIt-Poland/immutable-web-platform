{lib}:
with lib; 
  recursiveUpdate {
    environment = { 
      type = "dev"; 
      perspective = "root"; 
      preload = false;
    };
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
    modules = [];
  }