{pkgs, ...}: {
  imports = [
    <nixpkgs/nixos/maintainers/scripts/ec2/amazon-image.nix>
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    <nixpkgs/nixos/modules/profiles/headless.nix>
  ];
} 