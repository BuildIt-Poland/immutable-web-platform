let
  local-nixpkgs = (import ../nix { 
    env = "prod";
    system = "x86_64-linux"; 
  });
  helpers = import ./helpers.nix { nixpkgs = local-nixpkgs; };

  # TODO
  mkMaster = {}:{};
  mkNode = {}:{};
in
with local-nixpkgs;
{
  # issue with grub -> https://github.com/NixOS/nixpkgs/issues/62824
  # happen on c5 but not a t2 (micro and xlarge) - INVESTIGATE what is a difference on AWS
  # solution -> ln -s /dev/nvme0n1 /dev/xvda 
  buildit-ops = 
    { config, pkgs, nodes, ...}: 
    let
      kubernetes = import ./services/kubernetes.nix {
        inherit local-nixpkgs;
      };
    in
    {
      imports = [
        kubernetes
        # ./services/kubernetes.nix
      ];

      # _module.args.local-nixpkgs = local-nixpkgs;

      networking.domain = "my.xyz";

      swapDevices = [ ];

      environment.systemPackages = [ 
        neovim
        zsh
        htop
        curl
        kubectl
        virtualbox
        # knctl
        # kubectl-repl

        # TODO push to docker 
        # TODO change config to production from env
        k8s-cluster-operations.apply-cluster-stack 
        k8s-cluster-operations.apply-functions-to-cluster
      ];

      services.kubernetes.resources.auto-provision = true;

      # done here https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/cluster/kubernetes/default.nix#L221
      # virtualisation.docker = {
      #   enable = true;
      # };

      services.dockerRegistry.enable = true;

      environment.etc.local-source-folder.source = ./.;
      
      programs.zsh = {
        interactiveShellInit = ''
          echo "Hey hey hey"
          echo ${config.networking.privateIPv4}
        '';
        enable = true;
        enableCompletion = true;
      };

      users.extraUsers.root = {
        shell = zsh;
      };

      nix.gc = {
        automatic = true;
        # dates = "15 3 * * *"; # [1]
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