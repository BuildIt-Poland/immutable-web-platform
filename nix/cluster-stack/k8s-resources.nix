{stdenv, lib, pkgs, kubenix, yaml-to-json, charts}:
rec {

  knative-serving = yaml-to-json {
    name = "knative-serving";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/serving.yaml;
      sha256="177aq85d8933p9rby10v2g72sgs2a60q675qr1im55f1acf19llz";
    };
  };

  knative-crd = yaml-to-json {
    name = "knative-crd";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/serving-beta-crds.yaml;
      sha256="13ns3sc857qqipjdfdbjgcaj1sfkyspbv9dwvdw7jp91rlr73qrf";
    };
  };
  
  # https://github.com/knative/serving/pull/4096/files
  knative-monitoring = yaml-to-json {
    name = "knative-monitoring";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/monitoring.yaml;
      sha256="0cdpp1d3k39vghn5m6l6cxpqz5k935r1x4fq16k62ssnick3p0ss";
    };
  };

  knative-monitoring-metrics = yaml-to-json {
    name = "knative-monitoring-metrics";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/monitoring-metrics-prometheus.yaml;
      sha256="17rpma5rlbn0ng6jpcm04zmcc8pyhmn473yxplq1ci45jaxg8jya";
    };
  };

  # TODO local should be in mem - prod with elastic
  #  error: unable to recognize no matches for kind "Jaeger" in version "jaegertracing.io/v1"
  knative-e2e-request-tracing = yaml-to-json {
    name = "knative-e2e-request-tracing";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/monitoring-tracing-zipkin-in-mem.yaml;
      sha256="09dcdw22qbsfz7yy6c22k8a8jh8pg3rj4pr1j5a2vjr66dd2anaa";
    };
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
      knative-monitoring
      # INFO - I'm overriding it as dashboard has to be fixed
      # knative-e2e-request-tracing - monitoring include zipkin and argo is shouting about duplicate resources
    ];
    overridings = []; #monitoring-dashboard-fix;
  in
    (lib.foldl 
      lib.concat
      overridings
      ((builtins.map lib.importJSON jsons)));

  # core crd
  cert-manager-crd = yaml-to-json {
    name = "cert-manager-crd";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml;
      sha256 = "1a1sgh32x4ysf1mkdw4x8j5jj7xdcqcmw9a7h5qfpkl2yvn0cl18";
    };
  };

  cluster-crd = with kubenix.lib; toYAML (k8s.mkHashedList { 
    items = 
      (lib.foldl 
        lib.concat
        []
        (builtins.map lib.importJSON [
          charts.istio-init-json 
          cert-manager-crd
          knative-crd
        ]));
  });
}
