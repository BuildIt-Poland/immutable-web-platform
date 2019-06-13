let
  host-name = "example.org";
  local-nixpkgs = (import ../nix { 
    system = "x86_64-linux"; 
  });
  # local-nixpkgs = import <nixpkgs> {};
  containers = import ./container/example.nix;
  helpers = import ./helpers.nix { nixpkgs = local-nixpkgs; };
in
with local-nixpkgs;
{
  # issue with grub -> https://github.com/NixOS/nixpkgs/issues/62824
  # happen on c5 but not a t2 - INVESTIGATE what is a difference on AWS
  # solution -> ln -s /dev/nvme0n1 /dev/xvda 
  buildit-ops = 
    { config, pkgs, nodes, ...}: 
    {
      imports = [
        # ./services/concourse-ci.nix
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
            ${k8s-cluster-operations.apply-cluster-stack}/bin/apply-cluster-stack
          '';
          deps = [];
        };
      };

      environment.systemPackages = [ 
        neovim
        kubectl
        zsh
        htop
      ];

      virtualisation.docker.enable = true;
      virtualisation.rkt.enable = true;

      # system.autoUpgrade.enable = true;
      # system.autoUpgrade.channel = https://releases.nixos.org/nixos/unstable/nixos-19.09pre180188.2439b3049b1;

      # services.concourseci = {
      #   githubClientId = "";
      #   githubClientSecret = "";
      #   virtualhost = "buildit.com";
      #   sshPublicKeys = [];
      # };

      containers = containers;

      environment.etc.local-source-folder.source = ./.;
      
      programs.zsh = {
        interactiveShellInit = ''
          echo "Hey hey hey"
        '';
        enable = true;
        enableCompletion = true;
      };

      # neccessary to allow containers call outside world
      networking.nat.enable = true;
      networking.nat.internalInterfaces = ["ve-+"];

      users.extraUsers.root = {
        shell = local-nixpkgs.zsh;
      };

      nix.gc = {
        automatic = true;
        dates = "15 3 * * *"; # [1]
      };

      nix.autoOptimiseStore = true;
      nix.trustedUsers = [];
      networking.firewall.allowedTCPPorts = [ 80 22 ];
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