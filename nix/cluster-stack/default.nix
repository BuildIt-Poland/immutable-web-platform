{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  writeScript,
  writeScriptBin,
  application,
  log,
  kubenix,
  lib
}:
with kubenix.lib;
let
  configuration = callPackage ./configurations.nix {};
in
rec {
  charts = callPackage ./charts.nix {};
  config = callPackage ./config.nix {
    inherit pkgs;
  };

  cluster-images = config.docker.export;

  result = k8s.mkHashedList { 
    items = 
      config.kubernetes.objects
      # TODO take all functions
      ++ application.functions.express-app.config.kubernetes.objects;

      # INFO having issue with knative compatibility - wip
      # ++ (lib.importJSON charts.istio-init)
      # ++ (lib.importJSON charts.istio);
  };

  k8s-resources = toYAML result;
  images = (lib.flatten application.function-images) ++ cluster-images;
}
