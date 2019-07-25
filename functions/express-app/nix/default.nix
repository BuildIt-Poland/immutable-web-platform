{ pkgs, env-config, kubenix, callPackage, writeScriptBin, lib, docker }@args:
with kubenix.lib;
rec {
  package = callPackage ./package.nix {};

  config = (kubenix.evalModules {
    inherit args;

    modules = [
      ./module.nix
    ];

  }).config;

  images = config.docker.export;
  result = k8s.mkHashedList { items = config.kubernetes.objects; };
  yaml = toYAML result;
}