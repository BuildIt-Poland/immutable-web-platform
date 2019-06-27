let
  host-name = "example.org";
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
    {
      imports = [
        ./services/kubernetes.nix
        ./services/monitoring-proxy.nix
      ];

      services.postfix = {
        enable = true;
        setSendmail = true;
      };

      networking.domain = "my.xyz";

      swapDevices = [ ];

      environment.systemPackages = [ 
        neovim
        zsh
        htop
        curl
        kubectl
        # knctl
        # kubectl-repl

        # TODO push to docker 
        # TODO change config to production from env
        k8s-cluster-operations.apply-cluster-stack 
      ];

      systemd.services.k8s-resources = {
        enable   = true;
        description = "Kubernetes provisioning";
       # wantedBy = [ "multi-user.target" ];
        requires = [ "kube-apiserver.service" "kube-controller-manager.service" ];
        environment = {
          KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
        };
        path = [
          k8s-cluster-operations.apply-cluster-stack 
          k8s-cluster-operations.apply-functions-to-cluster
          kubectl
        ];
        script = ''
          while [ ! -f /var/lib/kubernetes/secrets/cluster-admin-key.pem ]
          do
            sleep 1
          done

          apply-cluster-stack
          apply-functions-to-cluster
        '';
        serviceConfig.Type = "oneshot";
      };

      virtualisation.docker = {
        enable = true;
      };

      services.dockerRegistry.enable = true;
      # https://discourse.nixos.org/t/systemd-backend-or-using-nixops-to-manage-ubuntu/1546/3
      # https://releases.nixos.org/nixos/unstable/nixos-19.09pre183392.83ba5afcc96
      system.autoUpgrade.enable = true;
      system.autoUpgrade.channel = https://releases.nixos.org/nixos/unstable/nixos-19.09pre183392.83ba5afcc96;

      # https://github.com/mayflower/nixpkgs/blob/2e29412e9c33ebc2d78431dfc14ee2db722bcb30/nixos/modules/services/cluster/kubernetes/default.nix

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
        shell = local-nixpkgs.zsh;
      };

      nix.gc = {
        automatic = true;
        # dates = "15 3 * * *"; # [1]
      };

      nix.autoOptimiseStore = true;
      nix.trustedUsers = [];
      # TODO add ingress-controller
      # networking.firewall.allowedTCPPortRanges = [ 
      #   { from = 30000; to = 32000; }
      # ];
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