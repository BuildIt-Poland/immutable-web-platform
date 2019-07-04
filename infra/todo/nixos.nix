# TODO http://www.haskellforall.com/2018/08/nixos-in-production.html
# https://github.com/NixOS/nixops/issues/794
# {
#   imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
#   ec2.hvm = true;
# }

# nix-build --attr system ./infra/nixos.nix
# nix-instantiate --eval --strict --attr config.networking.firewall.allowedTCPPorts ./infra/nixos.nix
import <nixpkgs/nixos> {
  system = "x86_64-linux";

  configuration = {
    imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
    # imports = [
    #   # ./configuration.nix
    # ];
  };
}