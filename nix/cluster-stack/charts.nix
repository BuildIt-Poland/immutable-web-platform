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

  # copyPathToStore
  descriptors = stdenv.mkDerivation {
    name = "descriptors";
    src = ./external;
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
    '';
  };
}
# master - does not work
# istio-chart = pkgs.fetchgit {
#   url = "https://github.com/istio/istio";
#   rev = "4d341b96cbfb51418a9264ff61fc04d08f0cac73";
#   sha256 = "06014mnimxskg40zz8iz5bgmcmnwj77a9564x586xj0df9xf4bs0";
# };

# istio = chart2json {
#   name = "istio";
#   chart = "${istio-chart}/install/kubernetes/helm/istio";
#   namespace = "istio-system";
# };

# there is no official charts yet ...
# knative-chart = fetch {
#   chart = "knative";
#   repo = "https://storage.googleapis.com/triggermesh-charts";
#   version = "0.5.0";
#   sha256 = "0v6nqzcc9m1r68b9yw1rgz2bdgx6g597zhwvsw3w27h7ywlvml4z";
# };
# knative = chart2json {
#   name = "knative";
#   chart = knative-chart;
#   values = {
#   };
# };