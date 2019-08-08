let
  pkgs = (import ../../nix { 
    system = "x86_64-linux"; 
  });
  p = pkgs.sources.nixpkgs.outPath;
in
{
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
      echo "Hey hey hey! :D"
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
}