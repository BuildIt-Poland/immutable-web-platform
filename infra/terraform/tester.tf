variable "ssh_pub_key" {
  default = "~/.ssh/id_rsa.pub"
}

resource "nix_build" "nixpkgs" {
  expression_path = "./nixpkgs.nix"
  out_link        = "./pinned_nixpkgs"
}

resource "nix_build" "nixosimage" {
  # The nix path used to build the expression, if not set, it is taken from the environment.
  nix_path = "nixpkgs=${nix_build.nixpkgs.store_path}:sshpubkey=${pathexpand("${var.ssh_pub_key}")}"

  # We can inline expressions, but be sure to escape them properly.
  # In this example, this expression is building a base vm image to be uploaded to google cloud.
  expression = <<-EOF
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
      cp --reflink=auto $${image}/*.tar.gz $out
    ''
  EOF

  # Path to the nix expression to possible write, and then build.
  expression_path = "./vmimage-generated.nix"

  # Same as what you get from nix-build -o ...
  out_link = "./nixosimage"
}
