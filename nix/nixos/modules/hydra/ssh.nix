{pkgs, ...}: 
let
  project = pkgs.project-config.project;
in {
  config = {
    services.openssh.allowSFTP = false;
    services.openssh.passwordAuthentication = false;

    programs.ssh = {
      knownHosts = [
        { hostNames = [ "github.com" "140.82.118.4" ]; publicKey = ""; }
      ];

      extraConfig = ''
        StrictHostKeyChecking no
      '';
    };
  };
}