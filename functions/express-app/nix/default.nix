{ env-config, kubenix, callPackage, writeScriptBin, lib, docker }:
rec {
  package = callPackage ./package.nix {};
  config = (kubenix.evalModules {
    modules = [
      ./module.nix
      # https://github.com/xtruder/kubenix/blob/kubenix-2.0/modules/docker.nix#L37
      { docker.registry.url = env-config.docker.registry; }
    ];
  }).config;

  charts = callPackage ./charts.nix {};
  images = config.docker.export;
}