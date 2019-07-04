{ config, lib, pkgs, ...}:
with lib;
let
  containers = import ./container/example.nix;
in
{
  config = {
    # neccessary to allow containers call outside world
    networking.nat.enable = true;
    networking.nat.internalInterfaces = ["ve-+"];
    virtualisation.rkt.enable = true;
    containers = containers;
  };
}