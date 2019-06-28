{ machinesConfigPath ? ./machines.json }:

let
  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);

  makeMasterServer = machine: {   
    name  = machine.name;
    value =
      { config, pkgs, lib, nodes, ... }:
      let
        kubernetes = import ./kubernetes {
          inherit config pkgs nodes; 
        };
      in {
        imports = [
          kubernetes
        ];
        environment.variables.KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";#"${kubeConfig}";
        services.kubernetes.roles = [ "master" ];
        environment.systemPackages = with pkgs; [
          nfs-utils
          kubectl
        ];
      };
  };
  masterServers = map makeMasterServer machines.masters.configs;

  makeWorkerServer = machine: {   
    name  = machine.name;
    value =
      { config, pkgs, lib, nodes, ... }:
      let
        kubernetes = import ./kubernetes {
          inherit config pkgs nodes; 
          # oidc = machines.oidc;
        };
      in {
        imports = [
          kubernetes
        ];
        services.kubernetes.roles = [ "node" ];
        environment.systemPackages = with pkgs; [
          nfs-utils
        ];
      };
  }; 
  workerServers = map makeWorkerServer machines.workers.configs;

in {
  network.description = "k8s-cluster";
  network.enableRollback = true;

  defaults.imports = [
    # ../common.nix
  ];

}
//  builtins.listToAttrs masterServers
//  builtins.listToAttrs workerServers