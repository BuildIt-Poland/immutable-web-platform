let
  vbox = {
    deployment.targetEnv                    = "virtualbox";

    virtualisation.virtualbox.guest.enable = true;
    deployment.virtualbox.memorySize        = 4096;
    deployment.virtualbox.vcpu              = 2;
    deployment.virtualbox.headless          = true;
  };
in
{
  buildit-ops = 
    { config, pkgs, ... }: {
      users = {
        mutableUsers = false;
        extraUsers.myuser.extraGroups = ["docker"];
        users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
      };
    } // vbox;
}