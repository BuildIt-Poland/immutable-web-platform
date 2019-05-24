{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  writeScript,
  writeScriptBin,
  application,
  kubenix,
  lib
}:
with kubenix.lib;
let
  configuration = callPackage ./configurations.nix {};
in
rec {
  charts = callPackage ./charts.nix {};
  config = callPackage ./config.nix {};
  result = k8s.mkHashedList { 
    items = 
      config.kubernetes.objects
      # TODO take all functions
      ++ application.functions.express-app.config.kubernetes.objects;

      # INFO having issue with knative compatibility - wip
      # ++ (lib.importJSON charts.istio-init)
      # ++ (lib.importJSON charts.istio);
  };
  yaml = toYAML result;
  inject-sidecar-to = namespace: writeScript "inside-sidecar-to" ''
    ${pkgs.kubectl}/bin/kubectl label namespace ${namespace} istio-injection=enabled
  '';

  apply-knative-with-istio = writeScript "apply-knative-with-istio" ''
    ${pkgs.kubectl}/bin/kubectl apply -f ${configuration.istio-crds}/istio-crds.yaml
    ${pkgs.kubectl}/bin/kubectl apply -f ${configuration.istio}/istio-node-port.yaml
    ${inject-sidecar-to env-config.kubernetes.namespace.functions}

    ${pkgs.kubectl}/bin/kubectl apply -f ${configuration.knative-serving}/knative-serving.yaml
  '';

  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    cat ${yaml} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    echo "Applying helm charts"
    ${apply-knative-with-istio}
  '';

  push-docker-images-to-local-cluster = writeScriptBin "push-docker-images-to-local-cluster"
    (lib.concatMapStrings 
      (docker-image: ''
        echo "Pushing docker image to local cluster: ${docker-image}"
        ${pkgs.kind}/bin/kind load image-archive --name ${env-config.projectName} ${docker-image}
      '') (lib.flatten application.function-images));

  push-to-docker-registry = writeScriptBin "push-to-docker-registry"
    (lib.concatMapStrings 
      (docker-images: ''
        ${kubenix.lib.docker.copyDockerImages { 
          images = docker-images; 
          dest = env-config.docker.destination;
        }}/bin/copy-docker-images
      '') application.function-images);
}
