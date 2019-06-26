let
  vbox = {
    deployment.targetEnv                    = "virtualbox";
    # virtualisation.virtualbox.guest.enable  = true;
    deployment.virtualbox.memorySize        = 3 * 4096;
    deployment.virtualbox.vcpu              = 4; # not sure why but if this is greater than 4 there is an issue with vbox guest
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