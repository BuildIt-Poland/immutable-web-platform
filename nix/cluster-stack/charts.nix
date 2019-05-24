{
  kubenix,
  pkgs,
  stdenv
}:
with kubenix.lib.helm;
rec {
  brigade = fetch {
    chart = "brigade";
    repo = "https://brigadecore.github.io/charts";
    version = "1.0.0";
    sha256 = "0i5i3h346dz4a771zkgjpbx4hbyf7r6zfhvqhvfjv234dha4fj50";
  };

  istio-chart = fetch {
    chart = "istio";
    version = "1.1.0";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.0-rc.0/charts";
    sha256 = "0ippv2914hwpsb3kkhk8d839dii5whgrhxjwhpb9vdwgji5s7yfl";
  };

  istio = chart2json {
    name = "istio";
    chart = istio-chart;
    namespace = "istio-system";
  };

  istio-init-chart = fetch {
    chart = "istio-init";
    version = "1.1.0";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.0-rc.0/charts";
    sha256 = "1p86xkzqycpbgysdlzjbd6xspz1bmd4sb2667diln80qxwyv10fx";
  };

  istio-init = chart2json {
    name = "istio-init";
    chart = istio-init-chart;
    namespace = "istio-system";
  };
}