{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  writeScript,
  functions,
  kubenix,
  lib
}:
with kubenix.lib;
rec {
  charts = callPackage ./charts.nix {};
  config = callPackage ./config.nix {};
  result = k8s.mkHashedList { 
    items = 
      config.kubernetes.objects ++
      functions.express-app.config.kubernetes.objects;
      # ++ (lib.importJSON charts.istio-init)
      # ++ (lib.importJSON charts.istio);
  };
  yaml = toYAML result;

  apply-knative-with-istio = writeScript "apply-knative-with-istio" ''
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio-crds.yaml
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio.yaml

    kubectl label namespace default istio-injection=enabled
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.5.2/serving.yaml
  '';

  apply-cluster-stack = writeScript "apply-cluster-stack" ''
    echo "Applying helm charts"
    cat ${yaml} | ${pkgs.kubectl}/bin/kubectl apply -f -
    ${apply-knative-with-istio}
  '';

  # TODO take all functions

  init = stdenv.mkDerivation {
    name = "init-cluster-stack";
    version = env-config.version;
    src = ./.;
    phases = ["installPhase"];
    buildInputs = [];
    installPhase = ''
      mkdir -p $out/bin
      cp ${apply-cluster-stack} $out/bin/${apply-cluster-stack.name}
    '';
  };
}
