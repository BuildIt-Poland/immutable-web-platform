{config, pkgs, ...}: 
let
  project = pkgs.project-config.project;
in 
{
  imports = [];

  security.acme.certs."${config.networking.hostName}" = {
    # webroot = "/var/www/challenges";
    email = project.authorEmail;
  };

  networking.firewall.allowedTCPPorts = [ 
    80
    3000
  ];

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts."${config.networking.hostName}" = {
      addSSL = true;
      enableACME = true;
      locations."/" ={
        proxyPass = "http://localhost:3000";
      };
    };
  };
}