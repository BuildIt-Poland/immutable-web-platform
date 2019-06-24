let
  host-name = "example.org";
  local-nixpkgs = (import ../nix { 
    env = "prod";
    system = "x86_64-linux"; 
  });
  containers = import ./container/example.nix;
  helpers = import ./helpers.nix { nixpkgs = local-nixpkgs; };
in
with local-nixpkgs;
{
  # issue with grub -> https://github.com/NixOS/nixpkgs/issues/62824
  # happen on c5 but not a t2 (micro and xlarge) - INVESTIGATE what is a difference on AWS
  # solution -> ln -s /dev/nvme0n1 /dev/xvda 
  buildit-ops = 
    { config, pkgs, nodes, ...}: 
    {
      imports = [
        ./services/kubernetes.nix
        ./services/nginx.nix
      ];

      services.postfix = {
        enable = true;
        setSendmail = true;
      };

      system.userActivationScripts = {
        k8s-cluster = {
          text = ''
            echo "Applying cluster stuff"
          '';
          deps = [];
        };
      };
            # ${k8s-cluster-operations.apply-cluster-stack}/bin/apply-cluster-stack

      networking.domain = "my.xzy";

      boot.postBootCommands = "echo 'yay'";

      environment.systemPackages = [ 
        neovim
        kubectl
        zsh
        htop
        curl
        kubernetes-helm
        git
        # kubernetes
        # kubelet

        # TODO push to docker 
        # TODO change config to production from env
        k8s-cluster-operations.apply-cluster-stack
        k8s-cluster-operations.apply-functions-to-cluster
      ];

      # virtualisation.docker.enable = true;
      virtualisation.docker = {
        enable = true;
      };

      virtualisation.rkt.enable = true;
      services.dockerRegistry.enable = true;

      system.autoUpgrade.enable = true;
      system.autoUpgrade.channel = https://releases.nixos.org/nixpkgs/nixpkgs-19.09pre182717.b58ada326aa;

      # https://github.com/mayflower/nixpkgs/blob/2e29412e9c33ebc2d78431dfc14ee2db722bcb30/nixos/modules/services/cluster/kubernetes/default.nix

      # containers = containers;
      environment.etc.local-source-folder.source = ./.;
      
      #this stuff has to go to activation script
      programs.zsh = {
        interactiveShellInit = ''
          echo "Hey hey hey"
          echo ${config.networking.privateIPv4}
          apply-cluster-stack
          apply-functions-to-cluster
        '';
        enable = true;
        enableCompletion = true;
      };

      # neccessary to allow containers call outside world
      # networking.nat.enable = true;
      # networking.nat.internalInterfaces = ["ve-+"];

      users.extraUsers.root = {
        shell = local-nixpkgs.zsh;
      };

      nix.gc = {
        automatic = true;
        dates = "15 3 * * *"; # [1]
      };

      nix.autoOptimiseStore = true;
      nix.trustedUsers = [];
      networking.firewall.allowedTCPPorts = [ 
        80 
        22 
      ];

      nix.binaryCaches = [ "https://cache.nixos.org" ];
      nix.binaryCachePublicKeys = [];

      nix.buildMachines = [
        {
          hostName = "localhost";
          systems = [ "x86_64-linux" ];
          maxJobs = 6;
          supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
        }
      ];
    };
}
# not necessary
# ifconfig -a - need to check how to
# networking.nat.externalInterface = "enp0s3"; # enp0s8