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
    grafana = mkOption { type = types.int; default = 15300; };
    weavescope = mkOption { type = types.int; default = 15301; };
    zipkin = mkOption { type = types.int; default = 15302; };
  };  

  config = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts."${hostName}" = {
        # forceSSL = true;
        # enableACME = true;
        locations."/grafana" ={
          proxyPass = "http://buildit-ops.my.xyz:${toString cfg.grafana}";
        };
        locations."/weavescope" ={
          proxyPass = "http://buildit-ops.my.xyz:${toString cfg.weavescope}";
        };
        locations."/zipkin" ={
          proxyPass = "http://buildit-ops.my.xyz:${toString cfg.zipkin}";
        };
      };
    };
  };
}
# security.acme.certs."${host-name}" = {
#   # webroot = "/var/www/challenges";
#   email = "foo@example.com";
# };


# security.acme.preliminarySelfsigned = true;