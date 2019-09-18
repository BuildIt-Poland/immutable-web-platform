{config, pkgs, ...}: 
let
  project = pkgs.project-config.project;
  host-name = config.networking.hostName;
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
    443
  ];

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    appendHttpConfig = ''
    '';

    virtualHosts."${config.networking.hostName}" = {
      # addSSL = true;
      forceSSL = true;
      # it should be defined in project-config - it has to be aligned with external-dns
      # useACMEHost = "acme-v02.api.letsencrypt.org";
      enableACME = true;
      locations."/" ={
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
}