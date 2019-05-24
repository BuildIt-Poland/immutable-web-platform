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

  # get local IP:  
  # export IP_ADDRESS=$(kubectl get node  --output 'jsonpath={.items[0].status.addresses[0].address}'):
  # $(kubectl get svc $INGRESSGATEWAY --namespace istio-system   --output 'jsonpath={.spec.ports[?(@.port==80)].nodePort}')

  istio-crds = stdenv.mkDerivation {
    name = "istio-crds";
    src = pkgs.fetchurl {
      url = https://raw.githubusercontent.com/knative/serving/v0.5.2/third_party/istio-1.0.7/istio-crds.yaml;
      sha256="0s796sv3fhicsp8znr5b14lc674s1dyrlc8j852lw6p8a75b6af1";
    };
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out
      cp $src $out/istio-crds.yaml
    '';
  };

  istio = stdenv.mkDerivation {
    name = "istio";
    src = pkgs.fetchurl {
      url = https://raw.githubusercontent.com/knative/serving/v0.5.2/third_party/istio-1.0.7/istio.yaml;
      sha256="0h2m3imqvg2aaf4kkp9n56asxjgr4znxs5y1wp7ikxgrp5fmd873";
    };
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out
      cp $src $out/istio-load-balancer.yaml
      sed 's/LoadBalancer/NodePort/' $out/istio-load-balancer.yaml > $out/istio-node-port.yaml
    '';
  };

  knative-serving = stdenv.mkDerivation {
    name = "knative-serving";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.0/serving.yaml;
      sha256="0y9h2mw1f2rbhmv2qfsz2m2cppa1s725i9hni5105s3js07h0r0i";
    };
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out
      cp $src $out/knative-serving.yaml
    '';
  };

  inject-sidecar-to = namespace: writeScript "inside-sidecar-to" ''
    ${pkgs.kubectl}/bin/kubectl label namespace ${namespace} istio-injection=enabled
  '';

  # This has to dissapear
  apply-knative-with-istio = writeScript "apply-knative-with-istio" ''
    ${pkgs.kubectl}/bin/kubectl apply -f ${istio-crds}/istio-crds.yaml
    ${pkgs.kubectl}/bin/kubectl apply -f ${istio}/istio-node-port.yaml
    ${inject-sidecar-to "default"}
    ${pkgs.kubectl}/bin/kubectl apply -f ${knative-serving}/knative-serving.yaml
  '';

  apply-functions-to-cluster = writeScriptBin "apply-functions-to-cluster" ''
    ${pkgs.kubectl}/bin/kubectl apply -f ${yaml}
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
