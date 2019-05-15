let
  host-name = "example.org";
  local-nixpkgs = (import ../../nix { use-docker = true; });
in
{
  concourse = 
    { config, pkgs, ...}: {
      services.postfix = {
        enable = true;
        setSendmail = true;
      };

      nixpkgs.overlays = [
        (self: super:
          {
            arion-compose = super.callPackage ./arion-compose.nix { pkgs = local-nixpkgs; };
          })
      ];
      
      environment.systemPackages = [ 
        local-nixpkgs.pkgs.hello
        local-nixpkgs.arion
        local-nixpkgs.sourceFolder
      ];

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
      #     forceSSL = true;
      #     enableACME = true;
      #     locations."/" ={
      #       proxyPass = "http://localhost:3000";
      #     };
      #   };
      # };

      # security.acme.preliminarySelfsigned = true;

      nix.gc = {
        automatic = true;
        dates = "15 3 * * *"; # [1]
      };

      nix.autoOptimiseStore = true;
      nix.trustedUsers = [];
      networking.firewall.allowedTCPPorts = [ 80 22 ];
      nix.buildMachines = [
        {
          hostName = "localhost";
          systems = [ "x86_64-linux" ];
          maxJobs = 6;
          # for building VirtualBox VMs as build artifacts, you might need other 
          # features depending on what you are doing
          supportedFeatures = [ ];
        }
      ];
    };
}