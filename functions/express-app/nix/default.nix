{ env-config, kubenix, callPackage, writeScriptBin, lib, docker }:
with kubenix.lib;
rec {
  package = callPackage ./package.nix {};

  config = (kubenix.evalModules {
    modules = [
      ./module.nix
      # https://github.com/xtruder/kubenix/blob/kubenix-2.0/modules/docker.nix#L37
      { docker.registry.url = env-config.docker.registry; }
    ];
    args = {
      inherit env-config;
      inherit callPackage;
    };
  }).config;

  images = config.docker.export;
  result = k8s.mkHashedList { items = config.kubernetes.objects; };
  yaml = toYAML result;
}