{pkgs, ...}: 
let
  project = pkgs.project-config.project;
  host-name = project.make-sub-domain "hydra";
in 
{
  imports = [];

  security.acme.certs."${host-name}" = {
    # webroot = "/var/www/challenges";
    email = project.authorEmail;
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts."${host-name}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" ={
        proxyPass = "http://localhost:3000";
      };
    };
  };
}