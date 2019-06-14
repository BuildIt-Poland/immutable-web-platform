{stdenv, pkgs}:
rec {
  # this things can dissapear
  # istio-crds = stdenv.mkDerivation {
  #   name = "istio-crds";
  #   src = pkgs.fetchurl {
  #     url = https://raw.githubusercontent.com/knative/serving/v0.5.2/third_party/istio-1.0.7/istio-crds.yaml;
  #     sha256="0s796sv3fhicsp8znr5b14lc674s1dyrlc8j852lw6p8a75b6af1";
  #   };
  #   phases = ["installPhase"];
  #   installPhase = ''
  #     mkdir -p $out
  #     cp $src $out/istio-crds.yaml
  #   '';
  # };

  # istio = stdenv.mkDerivation {
  #   name = "istio";
  #   src = pkgs.fetchurl {
  #     url = https://raw.githubusercontent.com/knative/serving/v0.5.2/third_party/istio-1.0.7/istio.yaml;
  #     sha256="0h2m3imqvg2aaf4kkp9n56asxjgr4znxs5y1wp7ikxgrp5fmd873";
  #   };
  #   phases = ["installPhase"];
  #   installPhase = ''
  #     mkdir -p $out
  #     cp $src $out/istio-load-balancer.yaml
  #     sed 's/LoadBalancer/NodePort/' $out/istio-load-balancer.yaml > $out/istio-node-port.yaml
  #   '';
  # };

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
}
