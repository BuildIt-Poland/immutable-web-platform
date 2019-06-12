{pkgs, callPackage, buildGoPackage, fetchFromGitHub}:
let
  nix-terraform = callPackage ./terraform-provider-nix.nix {};
  nix-provider-nix = nix-terraform;
in
  pkgs.terraform_0_12.withPlugins (plugins: [
    plugins.openstack
    nix-provider-nix
  ])