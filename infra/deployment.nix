{ machinesConfigPath ? ./machines.json }:

let
  local-nixpkgs = (import ../nix { 
    env = "prod";
    system = "x86_64-linux"; 
  });
  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);

  makeMasterServer = machine: {   
    name  = machine.name;
    value =
      { config, pkgs, lib, nodes, ... }:
      let
        kubeadm-bootstrap = import ./kubeadm-bootstrap.nix {
          inherit config pkgs nodes local-nixpkgs; 
        };
      in {
        imports = [
          kubeadm-bootstrap
        ];
        # environment.variables.KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";#"${kubeConfig}";
        services.k8s.roles = [ "master" ];
        # services.k8s.kubelet.enable = true;
        environment.systemPackages = with local-nixpkgs; [
          nfs-utils
          kubectl
          kubernetes
          ethtool
          socat
          k8s-cluster-operations.apply-cluster-stack 
          k8s-cluster-operations.apply-functions-to-cluster
        ];
      };
  };
  masterServers = map makeMasterServer machines.masters.configs;

  makeWorkerServer = machine: {   
    name  = machine.name;
    value =
      { config, pkgs, lib, nodes, ... }:
      let
        kubeadm-bootstrap = import ./kubeadm-bootstrap.nix {
          inherit config pkgs nodes local-nixpkgs; 
        };
      in {
        imports = [
          kubeadm-bootstrap
        ];
        services.k8s.roles = [ "node" ];
        # services.k8s.kubelet.enable = true;
        environment.systemPackages = with local-nixpkgs; [
          nfs-utils
          kubernetes
          ethtool
          socat
          k8s-cluster-operations.apply-cluster-stack 
          k8s-cluster-operations.apply-functions-to-cluster
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