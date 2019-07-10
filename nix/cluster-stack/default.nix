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
  extra-k8s-resources = callPackage ./k8s-resources.nix {};
in
rec {
  config = callPackage ./config.nix {
    inherit pkgs;
  };
  inherit extra-k8s-resources;
  cluster-images = config.docker.export;

  k8s-cluster-resources = toYAML (k8s.mkHashedList { 
    items = 
        config.kubernetes.objects
        # has to be postponed - check helm instance -> and attach this
      ;
  });

  k8s-functions-resources = toYAML (k8s.mkHashedList { 
    # TODO make a helper to take all functions
    items = 
        extra-k8s-resources.knative-stack
        ++ application.functions.express-app.config.kubernetes.objects;
  });

  images = (lib.flatten application.function-images) ++ cluster-images;
}
