let
  vbox = {
    deployment.targetEnv                    = "virtualbox";
    deployment.virtualbox.memorySize        = 3 * 4096;
    deployment.virtualbox.vcpu              = 4; # not sure why but if this is greater than 4 there is an issue with vbox guest
    deployment.virtualbox.headless          = true;
    systemd.services.virtualbox.enable = false;
    # virtualisation.virtualbox.guest.enable  = true;
    # nixpkgs.config.virtualbox.enableExtensionPack = true;
  };
in
{
  buildit-ops = 
    { config, pkgs, ... }: {
      users = {
        mutableUsers = false;
        users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
      };
    } // vbox;
}