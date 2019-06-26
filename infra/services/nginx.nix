{ config, lib, pkgs, ...}:
with lib;
let
  hostName = "nana";
  cfg = config.services.k8s-proxy;
in
{
  options.services.k8s-proxy = {
    port = mkOption { type = types.int; default = 3001; };
    virtualhost = mkOption { type = types.str; };
    grafana = mkOption { type = types.int; default = 3001; };
  };  

  config = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts."${hostName}" = {
        forceSSL = true;
        enableACME = true;
        locations."/grafana" ={
          proxyPass = "http://localhost:${toString cfg.grafana}";
        };
        locations."/scope" ={
          proxyPass = "http://localhost:";
        };
      };
  #   services.nginx.virtualHosts."${cfg.virtualhost}" = {
  #     enableACME = true;
  #     forceSSL = true;
  #     locations."/" = {
  #       proxyPass = "http://localhost:${toString cfg.port}/";
  #       proxyWebsockets = true;
  #     };
  #   };
    };
  };
}
# security.acme.certs."${host-name}" = {
#   # webroot = "/var/www/challenges";
#   email = "foo@example.com";
# };


# security.acme.preliminarySelfsigned = true;