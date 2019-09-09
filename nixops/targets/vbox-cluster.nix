{ machinesConfigPath ? ../machines.json }:

let
  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);
  ssh-local-keys = {      
    users = {
      mutableUsers = false;
      users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
    };
  };

  makeMasterServer = machine: {
    name  = machine.name;
    value =
      { ... }:
      {
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
      } // ssh-local-keys;
  };
  masterServers = map makeMasterServer machines.masters.configs;

  makeWorkerServer = machine: {
    name  = machine.name;
    value =
      { ... }:
      {
        systemd.services.virtualbox.enable = false;
        deployment = {
          targetEnv = "virtualbox";
          virtualbox = {
            vcpu = 2;
            memorySize = 4096;
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
      } // ssh-local-keys;
  };
  workerServers = map makeWorkerServer machines.workers.configs;

in {}
//  builtins.listToAttrs masterServers
//  builtins.listToAttrs workerServers