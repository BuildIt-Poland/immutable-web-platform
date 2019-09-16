nix.gc = {
        automatic = true;
        dates = "15 3 * * *"; # [1]
      };


  i18n.defaultLocale = "en_US.UTF-8";

      nix.autoOptimiseStore = true;
      nix.trustedUsers = ["hydra" "hydra-evaluator" "hydra-queue-runner"];
      networking.firewall.allowedTCPPorts = [ config.services.hydra.port 80 22 ];
      nix.buildMachines = [
        {
          hostName = "localhost";
          systems = [ "x86_64-linux" "i686-linux" ];
          maxJobs = 6;
          # for building VirtualBox VMs as build artifacts, you might need other 
          # features depending on what you are doing
          supportedFeatures = [ ];
        }
      ];
    };