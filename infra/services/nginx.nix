{ config, lib, pkgs, ...}:
with lib;
let
in
{
  options.services.concourseci = {
    port = mkOption { type = types.int; default = 3001; };
    virtualhost = mkOption { type = types.str; };
  };  

  config = {

  };
}
# security.acme.certs."${host-name}" = {
#   # webroot = "/var/www/challenges";
#   email = "foo@example.com";
# };

# services.nginx = {
#   enable = true;
#   recommendedProxySettings = true;
#   recommendedGzipSettings = true;
#   recommendedOptimisation = true;
#   recommendedTlsSettings = true;

#   # TODO expose concourse 
#   virtualHosts."${host-name}" = {
#     # forceSSL = true;
#     # enableACME = true;
#     locations."/" ={
#       proxyPass = "http://localhost:8181";
#     };
#     locations."/arion" ={
#       proxyPass = "http://localhost:8000";
#     };
#   };
# };

# security.acme.preliminarySelfsigned = true;