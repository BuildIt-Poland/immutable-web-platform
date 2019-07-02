{ machinesConfigPath ? ./machines.json }:

let
  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);

  makeMasterServer = machine: {
    name  = machine.name;
    value =
      { ... }:
      {
        # because of interface creation order in vbox
        # services.flannel.iface = "enp0s8";
        systemd.services.virtualbox.enable = false;
        deployment = {
          targetEnv = "virtualbox";
          virtualbox = {
            vcpu = 2;
            memorySize = 2048;
            headless = true;
            #vmFlags = [];
          };
        };
      };
  };
  masterServers = map makeMasterServer machines.masters.configs;

  makeWorkerServer = machine: {
    name  = machine.name;
    value =
      { ... }:
      {
        # because of interface creation order in vbox
        # services.flannel.iface = "enp0s8";
        systemd.services.virtualbox.enable = false;
        deployment = {
          targetEnv = "virtualbox";
          virtualbox = {
            vcpu = 2;
            memorySize = 5024;
            headless = true;
            #vmFlags = [];
            disks = { 
              data = {
                port = 1;
                size = 5120; # 5Gb
              };
            };
          };
        };
        fileSystems.data = {
          device = "/dev/sdb";
          fsType = "xfs";
          label = "data";
          autoFormat = true;
          mountPoint = "/data";
        };
      };
  };
  workerServers = map makeWorkerServer machines.workers.configs;

in {}
//  builtins.listToAttrs masterServers
//  builtins.listToAttrs workerServers