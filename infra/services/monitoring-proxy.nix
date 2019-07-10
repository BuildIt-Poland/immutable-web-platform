{ config, lib, pkgs, ...}:
with lib;
let
  hostName = config.networking.privateIPv4;
  # hostName = "localhost";
  cfg = config.services.k8s-proxy;
in
{
  options.services.k8s-proxy = {
    port = mkOption { type = types.int; default = 3001; };
    virtualhost = mkOption { type = types.str; };
  };  

  config = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      # appendHttpConfig = "listen 127.0.0.1:80;";

      virtualHosts."${hostName}" = {
        # forceSSL = true;
        # enableACME = true;
      };
    };
  };
}
# security.acme.certs."${host-name}" = {
#   # webroot = "/var/www/challenges";
#   email = "foo@example.com";
# };


# security.acme.preliminarySelfsigned = true;