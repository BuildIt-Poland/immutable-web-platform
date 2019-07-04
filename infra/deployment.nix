{ machinesConfigPath ? ./machines.json }:

let
  local-nixpkgs = (import ../nix { 
    env = "prod";
    system = "x86_64-linux"; 
  });

  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);

  kube-scripts = local-nixpkgs.callPackage ./kubeadm-scripts.nix {};

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
        # machine.pod-cidr
        services.k8s.roles = [ "master" ];
        environment.systemPackages = with local-nixpkgs; [
          kubectl
          kubernetes
          ethtool
          socat
          k8s-cluster-operations.apply-cluster-stack 
          k8s-cluster-operations.apply-functions-to-cluster
        ] ++ (kube-scripts.make-master {
          ip = config.networking.privateIPv4; 
          pods-cidr = machine.pods-cidr; 
        });
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
        environment.systemPackages = with local-nixpkgs; [
          kubernetes
          ethtool
          socat
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