let
  pkgs = ((import <nixpkgs>) {
    system = "x86_64-linux";
  });
    
  configuration = {config, pkgs, ...}: {
    imports = [
      # <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
      # https://github.com/NixOS/nixpkgs/blob/master/nixos/maintainers/scripts/ec2/amazon-image.nix
      <nixpkgs/nixos/maintainers/scripts/ec2/amazon-image.nix>
    ];

    users.users.root = {
      openssh.authorizedKeys.keys = [
        (builtins.readFile <sshpubkey>)
      ];
    };

  };

  nixos = ((import <nixpkgs/nixos>) {
    configuration = configuration;
    system = "x86_64-linux";
  });

  image = nixos.config.system.build.amazonImage;
in 
  pkgs.runCommand "image.tar.gz" {} ''
    cp --reflink=auto ${image}/*.tar.gz $out
  ''
