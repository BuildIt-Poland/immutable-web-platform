{pkgs, ...}: {
  imports = [];

  environment.systemPackages = [ 
    pkgs.zsh
    pkgs.vim
  ];

  programs.zsh = {
    interactiveShellInit = ''
      echo "Hey hey hey sailor!!!"
    '';
    enable = true;
    enableCompletion = true;
  };

  users.extraUsers.root = {
    shell = pkgs.zsh;
  };
}