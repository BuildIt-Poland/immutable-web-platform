
{ config, pkgs, lib, ... }:
with lib;
let
  serviceName = "hello-rkt";
  cfg = config.services."${serviceName}";
in
{ 
  options.services."${serviceName}" = {
    port = mkOption { type = types.int; default = 8000; };
    sshPublicKeys = mkOption { type = types.listOf types.str; };
  };

  config = {
    systemd.services."${serviceName}" = {
      path = [pkgs.rkt];
      description = "Hello rkt";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.rkt}/bin/rkt run --insecure-options=image \
            --port=8000-tcp:${builtins.toString cfg.port} \
            docker://crccheck/hello-world \
            --name ${serviceName}
        '';
        ExecStop = ''
          ${pkgs.rkt}/bin/rkt stop --force --name ${serviceName}
        '';
        KillMode = "mixed";
        Restart = "always";
      };
    };

    users.extraGroups.rkt = {};
    users.extraUsers.rkt-user = {
      home = "/srv/rkt-user";
      createHome = true;
      isSystemUser = true;
      extraGroups = [ "rkt" ];
      openssh.authorizedKeys.keys = cfg.sshPublicKeys;
      shell = pkgs.bashInteractive;
    };
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}