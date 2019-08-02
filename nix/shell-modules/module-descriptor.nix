{config, pkgs, kubenix, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
{
  imports = [ ];

  options.modules = {
    kubernetes = mkOption {
      default = {};
    };

    packages = mkOption {
      default = {};
    };

    tests = mkOption {
      default = {};
    };

    docker = mkOption {
      default = {};
    };
  };
}