{config, pkgs, ...}: 
let
  project = pkgs.project-config.project;
  host-name = config.networking.hostName;
in 
{
  imports = [];

  security.acme = {
    certs."${config.networking.hostName}" = {
      # webroot = "/var/www/challenges";
      email = project.authorEmail;
    };
    production = false;
  };

  networking.firewall.allowedTCPPorts = [ 
    80
    3000
    443
  ];

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    # https://acme-staging-v02.api.letsencrypt.org/directory
    virtualHosts."${host-name}" = {
      forceSSL = true;
      enableACME = true;
      # hydra
      locations."/" ={
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
}