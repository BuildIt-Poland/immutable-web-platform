let
  host-name = "example.org";
  local-nixpkgs = (import ../nix { use-docker = true; });
  containers = import ./container/example.nix;
  helpers = import ./helpers.nix { nixpkgs = local-nixpkgs; };
in
{
  buildit-ops = 
    { config, pkgs, nodes, ...}: 
    {
      imports = [
        ./services/concourse-ci.nix
        ./services/kubernetes.nix
        ./services/nginx.nix
      ];

      services.postfix = {
        enable = true;
        setSendmail = true;
      };

      environment.systemPackages = with local-nixpkgs; [ 
        neovim
        kubectl
        zsh
        htop
      ];

      system.autoUpgrade.enable = true;
      system.autoUpgrade.channel = https://releases.nixos.org/nixos/unstable/nixos-19.09pre180188.2439b3049b1;

      services.concourseci = {
        githubClientId = "";
        githubClientSecret = "";
        virtualhost = "buildit.com";
        sshPublicKeys = [];
      };

      containers = containers;

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
# not necessary
# ifconfig -a - need to check how to
# networking.nat.externalInterface = "enp0s3"; # enp0s8