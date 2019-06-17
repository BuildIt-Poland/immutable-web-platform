{stdenv, lib, pkgs, kubenix}:
rec {
  # TODO wrap by chart
  yaml-to-json = {src, name, version}:
    stdenv.mkDerivation {
      inherit name version src;
      phases = ["installPhase"];
      buildInputs = [pkgs.remarshal pkgs.gawk pkgs.jq];
      installPhase = ''
        awk 'BEGIN{i=1}{line[i++]=$0}END{j=1;n=0; while (j<i) {if (line[j] ~ /^---/) n++; else print line[j] >>"resource-"n".yaml"; j++}}' $src

        for file in ./resource-*.yaml
        do
          remarshal -i $file -if yaml -of json >>resources.jsonl
        done

        # convert jsonl file to json array, remove null values and write to $out
        cat resources.jsonl | jq -Scs 'walk(
          if type == "object" then
            with_entries(select(.value != null))
          elif type == "array" then
            map(select(. != null))
          else
            .
          end)' > $out
      '';
    };

  knative-serving = yaml-to-json {
    name = "knative-serving";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/serving.yaml;
      sha256="0y9h2mw1f2rbhmv2qfsz2m2cppa1s725i9hni5105s3js07h0r0i";
    };
  };

  knative-monitoring = yaml-to-json {
    name = "knative-monitoring";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/monitoring-metrics-prometheus.yaml;
      sha256="17rpma5rlbn0ng6jpcm04zmcc8pyhmn473yxplq1ci45jaxg8jyg";
    };
  };

  knative-monitoring-json = 
    (lib.importJSON knative-monitoring);

  knative-serving-json = 
    (lib.importJSON knative-serving);
}
