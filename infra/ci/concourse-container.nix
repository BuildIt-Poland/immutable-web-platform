{nixpkgs}:{
  database = { 
    autoStart = true;
    config =
      { config, pkgs, ... }:
      { 
        # services.postgresql.enable = true;
        # services.postgresql.package = pkgs.postgresql_9_6;

        # services.httpd.enable = true;
        # services.httpd.adminAddr = "foo@example.org";
        # networking.firewall.allowedTCPPorts = [ 8181 80 ];
      };
  };
}
  # concourse-ci =  { 
  # autoStart = true;
  # # path = "/nix/var/nix/profiles/webserver"; 
  # bindMounts = { "/webroot" = { 
  #                 hostPath="/home/wavewave/www";
  #                 isReadOnly = true; 
  #               };
  #               "/home/wavewave/temp" = { 
  #                 isReadOnly = false; 
  #             };
  #           };
  # config =
  # {config, pkgs, ...}:
  # { networking.firewall.enable = false;
  #   services.openssh.enable = true;     
  #   services.lighttpd = {
  #     enable = true;
  #     document-root = "/webroot";
  #   };      
  # };