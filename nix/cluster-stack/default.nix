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

  k8s-cluster-resources = toYAML (k8s.mkHashedList { 
    items = config.kubernetes.objects;
  });

  k8s-functions-resources = toYAML (k8s.mkHashedList { 
    # TODO make a helper to take all functions
    items = application.functions.express-app.config.kubernetes.objects;
  });

  images = (lib.flatten application.function-images) ++ cluster-images;
}
