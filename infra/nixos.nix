# TODO http://www.haskellforall.com/2018/08/nixos-in-production.html
# https://github.com/NixOS/nixops/issues/794
# {
#   imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
#   ec2.hvm = true;
# }
import <nixpkgs/nixos> {
  system = "x86_64-linux";

  configuration = {
    # imports = [
    #   # ./configuration.nix
    # ];
  };
}