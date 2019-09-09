{ config, pkgs, lib, ... }:
with lib;
let
  serviceName = "hello-python";
  cfg = config.services."${serviceName}";

  start-server = pkgs.writeScript "start-server" ''
    #!${pkgs.bash}/bin/bash

    export WEB_ROOT="${pkgs.nix.doc}/share/doc/nix/manual"
    cd "$WEB_ROOT"
    ${pkgs.python3}/bin/python -m http.server ${builtins.toString cfg.port}
  '';
in
{ 
  options.services."${serviceName}" = {
    port = mkOption { type = types.int; default = 8000; };
    sshPublicKeys = mkOption { type = types.listOf types.str; };
  };
  config = {
    systemd.services."${serviceName}" = {
      description = "Hello python";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${start-server}";
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}