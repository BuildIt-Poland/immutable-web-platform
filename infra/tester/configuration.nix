let
  nixpkgs = (import ../../nix { 
    system = "x86_64-linux"; 
  });
  p = nixpkgs.sources.nixpkgs.outPath;
in
# with pkgs;
{
  # TODO nginx serve results from test run

  network.description = "buildit-tester-network";
  # investigating https://github.com/NixOS/nixpkgs/issues/6956
  # https://github.com/NixOS/nixpkgs/pull/21943
  buildit-tester = {config, pkgs, ...}: {
    imports = [
      <nixpkgs/nixos/modules/profiles/minimal.nix>
      <nixpkgs/nixos/modules/profiles/headless.nix>
    ];

    ec2.hvm = true;

    environment.systemPackages = [ 
      pkgs.zsh
      pkgs.vim
    ];

    environment.etc.source.source = ../../.;

    programs.zsh = {
      interactiveShellInit = ''
        echo "Hey hey hey"
      '';
      enable = true;
      enableCompletion = true;
    };

    nix.nixPath = [ "nixpkgs=${p}" ];
    nix.package = pkgs.nixUnstable;

    users.extraUsers.root = {
      shell = pkgs.zsh;
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
  };
}