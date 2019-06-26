{ config, lib, pkgs, ...}:
with lib;
let
  containers = import ./container/example.nix;
in
{
  options.services.concourseci = {
    port = mkOption { type = types.int; default = 3001; };
    virtualhost = mkOption { type = types.str; };
  };  

  config = {

    # neccessary to allow containers call outside world
    networking.nat.enable = true;
    networking.nat.internalInterfaces = ["ve-+"];
    virtualisation.rkt.enable = true;
    containers = containers;
  };
}