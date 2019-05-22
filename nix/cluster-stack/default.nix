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
rec {
  charts = callPackage ./charts.nix {};
  config = callPackage ./config.nix {};
  result = k8s.mkHashedList { 
    items = 
      config.kubernetes.objects

      # TODO take all functions
      ++ application.functions.express-app.config.kubernetes.objects;
      # ++ (lib.importJSON charts.istio-init)
      # ++ (lib.importJSON charts.istio);
  };
  yaml = toYAML result;

  # This has to dissapear
  apply-knative-with-istio = writeScript "apply-knative-with-istio" ''
    ${pkgs.kubectl}/bin/kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio-crds.yaml
    ${pkgs.kubectl}/bin/kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio.yaml

    ${pkgs.kubectl}/bin/kubectl label namespace default istio-injection=enabled
    ${pkgs.kubectl}/bin/kubectl apply --filename https://github.com/knative/serving/releases/download/v0.5.2/serving.yaml
  '';

  apply-cluster-stack = writeScriptBin "apply-cluster-stack" ''
    echo "Applying helm charts"
    cat ${yaml} | ${pkgs.kubectl}/bin/kubectl apply -f -
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
