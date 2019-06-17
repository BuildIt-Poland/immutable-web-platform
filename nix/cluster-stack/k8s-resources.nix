{stdenv, pkgs}:
rec {
  # TODO wrap by chart
  knative-serving = stdenv.mkDerivation {
    name = "knative-serving";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/serving.yaml;
      sha256="0y9h2mw1f2rbhmv2qfsz2m2cppa1s725i9hni5105s3js07h0r0i";
    };
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out
      cp $src $out/knative-serving.yaml
    '';
  };
}
