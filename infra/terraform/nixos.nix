let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/91fa6990b2505fb6c01850f13954917f1c168383.tar.gz"; 
    sha256 = "1xsaz9n41p8yxqxf78lh74bbpvgnymdmq1hvnagra7r6bp3jp7ad";
  };

in
  import "${nixpkgs}/nixos" {
    configuration = {
      imports = [
        <nixpkgs/nixos/maintainers/scripts/ec2/amazon-image.nix>
        ./configuration.nix
      ];
    };

    system = "x86_64-linux";
  }
