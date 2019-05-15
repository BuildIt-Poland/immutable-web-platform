let
  host-name = "example.org";
  local-nixpkgs = (import ../../nix { use-docker = true; });
  # arion = local-nixpkgs.pkgs.callPackage ./arion.nix {};
  arion = local-nixpkgs.pkgs.callPackage ./arion.nix {};

  arionSrc = (builtins.fetchGit "https://github.com/hercules-ci/arion");
  arionFn =  import (arionSrc.outPath + "/arion.nix");
in
{
  concourse = 
    { config, pkgs, ...}: {
      services.postfix = {
        enable = true;
        setSendmail = true;
      };

      environment.systemPackages = [ 
        local-nixpkgs.pkgs.hello
        local-nixpkgs.pkgs.coreutils
        (pkgs.callPackage arionFn {})
        # arion
        # local-nixpkgs.pkgs.arion
      ];
      # [ 
      #   pkgs.bash
      #   pkgs.docker_compose 
      #   nixpkgs_.pkgs.hello
      # ];

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
       nix.useSandbox = true;

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