let
  host-name = "example.org";
  local-nixpkgs = (import ../../nix { use-docker = true; });
  containers = import ./concourse-container.nix;
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

      # copying source to etc - cool!
      # https://groups.google.com/forum/#!topic/nix-devel/0AS_sEH7n-M
      environment.etc.my-source.source = ./.;

      docker-containers.test-concourse = {
        image = "karthequian/helloworld";
        ports = ["8181:80"];
      };

      containers = containers;
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