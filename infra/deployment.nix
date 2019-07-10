{ machinesConfigPath ? ./machines.json }:

let
  pkgs = (import ../nix { 
    env = "prod";
    system = "x86_64-linux"; 
  });

  machines = import ./machines.nix {
    inherit machinesConfigPath;
  };

  makeMasterServer = machine: {   
    name  = machine.name;
    value =
      { config, lib, nodes, ... }:
      let
        kubernetes = import ./module/kubernetes {
          inherit config nodes pkgs;
        };
      in {
        imports = [
          kubernetes
        ];

        services.k8s.roles = [ "master" ];
        services.k8s.pods-cidr = machine.pods-cidr;

        environment.systemPackages = with pkgs; [
          k8s-cluster-operations.apply-cluster-stack 
          k8s-cluster-operations.apply-functions-to-cluster
        ];
      };
  };

  makeWorkerServer = machine: {   
    name  = machine.name;
    value =
      { config, lib, nodes, ... }:
      let
        kubernetes = import ./module/kubernetes {
          inherit config nodes pkgs;
        };
      in {
        imports = [
          kubernetes
        ];
        services.k8s.roles = [ "node" ];
      };
  }; 

  masterServers = map makeMasterServer machines.masters.configs;
  workerServers = map makeWorkerServer machines.workers.configs;
in {
  network.description = "k8s-cluster";
  network.enableRollback = true;

  defaults.imports = [
    (import ./configuration {
      pkgs = pkgs; 
    })
  ];
}
//  builtins.listToAttrs masterServers
//  builtins.listToAttrs workerServers