{ config, lib, pkgs, ...}:
with lib;
let
in
{
  options.services.concourseci = {
    port = mkOption { type = types.int; default = 3001; };
    virtualhost = mkOption { type = types.str; };
    githubUser = mkOption { type = types.str; default = "damianbaar"; };
    githubClientId =  mkOption { type = types.str; };
    githubClientSecret =  mkOption { type = types.str; };
    sshPublicKeys = mkOption { type = types.listOf types.str; };
    subnet = mkOption { type = types.str; default = "172.21.0.0/16"; };
    registryIP = mkOption { type = types.str; default = "172.21.0.254"; };
  };  

  # config = {
  #   networking.hosts."${cfg.registryIP}" = [ "ci-registry" ];
  #   virtualisation.docker.extraOptions = "--insecure-registry=ci-registry:5000";

  # database = { 
  #   autoStart = true;
  #   config =
  #     { config, pkgs, ... }:
  #     { 
  #       services.postgresql.enable = true;
  #       services.postgresql.package = pkgs.postgresql;
  #     };
  # };

  #   systemd.services.concourseci = {
  #     enable   = true;
  #     wantedBy = [ "multi-user.target" ];
  #     requires = [ "docker.service" ];
  #     serviceConfig = {
  #       ExecStart = "${pkgs.docker_compose}/bin/docker-compose -f '${dockerComposeFile}' up";
  #       ExecStop  = "${pkgs.docker_compose}/bin/docker-compose -f '${dockerComposeFile}' down";
  #       Restart   = "always";
  #       User      = "concourseci";
  #       WorkingDirectory = "/srv/concourseci";
  #     };
  #   };

  #   services.nginx.virtualHosts."${cfg.virtualhost}" = {
  #     enableACME = true;
  #     forceSSL = true;
  #     locations."/" = {
  #       proxyPass = "http://localhost:${toString cfg.port}/";
  #       proxyWebsockets = true;
  #     };
  #   };

  #   users.extraUsers.concourseci = {
  #     home = "/srv/concourseci";
  #     createHome = true;
  #     isSystemUser = true;
  #     extraGroups = [ "docker" ];
  #     openssh.authorizedKeys.keys = cfg.sshPublicKeys;
  #     shell = pkgs.bashInteractive;
  #   };
  # };
}