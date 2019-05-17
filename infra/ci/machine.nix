{
  concourse = 
    { config, pkgs, ... }: {
      deployment.targetEnv                    = "virtualbox";

      virtualisation.docker.enable = true;
      virtualisation.rkt.enable = true;

      virtualisation.virtualbox.guest.enable = true;
      deployment.virtualbox.memorySize        = 4096;
      deployment.virtualbox.vcpu              = 2;
      deployment.virtualbox.headless          = true;

      services.nixosManual.showManual         = false;
      services.ntp.enable                     = false;

      users = {
        mutableUsers = false;
        extraUsers.myuser.extraGroups = ["docker"];
        users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
      };
    };
}