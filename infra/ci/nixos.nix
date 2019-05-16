let
  host-name = "example.org";
  local-nixpkgs = (import ../../nix { use-docker = true; });
  containers = import ./concourse-container.nix;
  start-arion = local-nixpkgs.writeScript "start-arion" ''
    #!${local-nixpkgs.bash}/bin/bash
    source /etc/bashrc
    ${local-nixpkgs.arion}/bin/arion \
      --file ${local-nixpkgs.arion-compose}/arion-compose.nix \
      --pkgs ${local-nixpkgs.arion-compose}/arion-pkgs.nix \
      up
  '';
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
        local-nixpkgs.arion
        local-nixpkgs.run-arion
      ];

      systemd.services."test-service" = {
        description = "arion-compose";
        after = [ "docker.service" "docker.socket"];
        requires = [ "docker.service" "docker.socket"  ];
        wantedBy = [ "multi-user.target" ];
        # path = ["dupa/szatana"];
        serviceConfig = {
          ExecStart =  "${start-arion}";
          ExecStop = ''
            ${local-nixpkgs.arion}/bin/arion \
              --file ${local-nixpkgs.arion-compose}/arion-compose.nix \
              --pkgs ${local-nixpkgs.arion-compose}/arion-pkgs.nix \
              rm
          '';
          TimeoutStartSec = 1000;
          TimeoutStopSec = 1200;
        };
      };
      systemd.services.test-service.enable = true;

      docker-containers.concourse = {
        image = "karthequian/helloworld";
        ports = ["8181:80"];
      };

      containers = containers {nixpkgs = local-nixpkgs;};
      #  {config, ...}: {
      #     autoStart=true; 
      #     config = {...}: {
      #     };
      #  };
    # };

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