{
  pkgs, 
  callPackage,
  # application,
  kubenix,
  k8s-resources,
  lib
}:
with kubenix.lib;
let
  knative-stack-json = with k8s-resources; helm.concat-json { 
    jsons = [
      knative-serving-json
      knative-monitoring-json
    ];
  };

  cluster-crd-json = with k8s-resources; helm.concat-json {
    jsons = [
      k8s-resources.istio-init-json 
      cert-manager-crd-json
      knative-crd-json
    ];
  };
in
rec {
  config = callPackage ./config.nix {};

  k8s-cluster-crd = helm.jsons-to-yaml (
    cluster-crd-json
  );

  k8s-cluster-resources = helm.jsons-to-yaml (
    config.kubernetes.objects
  );

  k8s-functions-resources = helm.jsons-to-yaml 
    (knative-stack-json
    # ++ application.functions.express-app.config.kubernetes.objects);
    );

  resources = {
    crd = k8s-cluster-crd;
    cluster= k8s-cluster-resources;
    functions = k8s-functions-resources;
  };

  images = 
     []
    #  (lib.flatten application.function-images)
  ++ config.docker.export;
}
