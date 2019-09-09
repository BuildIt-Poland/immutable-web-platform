{pkgs, ...}: {
  imports = [
  ];

  environment.systemPackages = [ 
    pkgs.zsh
    pkgs.vim
  ];

  environment.etc.source.source = ../../.;

  programs.zsh = {
    interactiveShellInit = ''
      echo "Hey hey hey sailor!"
    '';
    enable = true;
    enableCompletion = true;
  };

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