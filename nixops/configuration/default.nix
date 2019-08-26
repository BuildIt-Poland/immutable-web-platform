{ pkgs, ...}: 
with pkgs;
{
  environment.systemPackages = [ 
    zsh
  ];

  programs.zsh = {
    interactiveShellInit = ''
      echo "Hey hey hey"
    '';
    enable = true;
    enableCompletion = true;
  };

  users.extraUsers.root = {
    shell = zsh;
  };

  nix.gc.automatic = true;
  nix.autoOptimiseStore = true;

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
}