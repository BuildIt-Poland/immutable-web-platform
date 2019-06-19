{stdenv, lib, pkgs, kubenix, yaml-to-json}:
rec {

  knative-serving = yaml-to-json {
    name = "knative-serving";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/serving.yaml;
      sha256="0y9h2mw1f2rbhmv2qfsz2m2cppa1s725i9hni5105s3js07h0r0i";
    };
  };
  
  # https://github.com/knative/serving/pull/4096/files
  knative-monitoring = yaml-to-json {
    name = "knative-monitoring";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/monitoring.yaml;
      sha256="1h1x1wx7dyxhxpx0827azdadyw9vzpzrgm1l5fl0kzz4xm79488i";
    };
  };

  knative-monitoring-metrics = yaml-to-json {
    name = "knative-monitoring-metrics";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/monitoring-metrics-prometheus.yaml;
      sha256="17rpma5rlbn0ng6jpcm04zmcc8pyhmn473yxplq1ci45jaxg8jyg";
    };
  };

  # TODO local should be in mem - prod with elastic
  #  error: unable to recognize no matches for kind "Jaeger" in version "jaegertracing.io/v1"
  knative-e2e-request-tracing = yaml-to-json {
    name = "knative-e2e-request-tracing";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/monitoring-tracing-zipkin-in-mem.yaml;
      sha256="09dcdw22qbsfz7yy6c22k8a8jh8pg3rj4pr1j5a2vjr66dd2ana0";
    };
  };

  weavescope = 
    pkgs.stdenv.mkDerivation {
      name = "waveworks-scope";
      phases = ["installPhase"];
      installPhase = ''
        curl -L "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')" > file.yaml
        remarshal -i file.yaml -if yaml -of json | jq '.items' > $out
      '';
      nativeBuildInputs = [
        pkgs.curl 
        pkgs.kubectl 
        pkgs.cacert 
        pkgs.remarshal 
        pkgs.jq
      ];
    };

  scaling-dashboard = (builtins.readFile ../grafana/knative-scaling.json);
  monitoring-dashboard-fix = 
    let
      src = lib.importJSON knative-monitoring;
      remapDashboard = builtins.map (
        x: if (lib.hasAttrByPath ["data" "scaling-dashboard.json"] x)
          then (x // ({ data."scaling-dashboard.json" = ''${scaling-dashboard}'';}))
          else x
      );
    in 
      remapDashboard src;

  knative-stack = 
  let
    jsons = [
      knative-serving
      # INFO - I'm overriding it as dashboard has to be fixed
      # knative-monitoring
      knative-e2e-request-tracing
      weavescope
    ];
    overridings = monitoring-dashboard-fix;
  in
    (lib.foldl 
      lib.concat
      overridings
      (builtins.map lib.importJSON jsons));
}
