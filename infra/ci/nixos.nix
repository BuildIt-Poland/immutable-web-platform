let
  host-name = "example.org";
  local-nixpkgs = (import ../../nix { use-docker = true; });
  containers = import ./concourse-container.nix;
  helpers = import ./helpers.nix { nixpkgs = local-nixpkgs; };
in
{
  concourse = 
    { config, pkgs, ...}: {
      services.postfix = {
        enable = true;
        setSendmail = true;
      };

      environment.systemPackages = [ 
        local-nixpkgs.arion
      ];

      # systemd.services."concourse-ci" = {
      #   enable = true;
      #   description = "Concourse CI";
      #   after = [ "docker.service" "docker.socket"];
      #   requires = [ "docker.service" "docker.socket"  ];
      #   wantedBy = [ "multi-user.target" ];
      #   serviceConfig = {
      #     ExecStart =  "${helpers.start-arion}";
      #     ExecStop = "${helpers.stop-arion}";
      #     TimeoutStartSec = 0;
      #     TimeoutStopSec = 100;
      #   };
      # };

      services.kubernetes = {
        roles = ["master" "node"];
      };

      docker-containers.hello-world = {
        image = "karthequian/helloworld";
        ports = ["8181:80"];
      };

      containers = containers {nixpkgs = local-nixpkgs;};

      # security.acme.certs."${host-name}" = {
      #   # webroot = "/var/www/challenges";
      #   email = "foo@example.com";
      # };

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;

        # TODO expose concourse 
        virtualHosts."${host-name}" = {
          # forceSSL = true;
          # enableACME = true;
          locations."/" ={
            proxyPass = "http://localhost:8181";
          };
          locations."/arion" ={
            proxyPass = "http://localhost:8000";
          };
        };
      };

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