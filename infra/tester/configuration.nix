let
  nixpkgs = (import ../../nix { 
    system = "x86_64-linux"; 
  });
in
{
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


    nix.gc.automatic = true;
    nix.autoOptimiseStore = true;

    users.extraUsers.root = {
      shell = pkgs.zsh;
    };

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