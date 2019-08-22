{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  imports = [
  ];

  options.storage = {
    provisioner = mkOption {
      default = "ceph.rook.io/block";
    };
  };
}