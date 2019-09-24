{lib, pkgs, kubenix, k8s-resources}:
with pkgs;
with kubenix.lib;
rec {

  istio-src = pkgs.fetchFromGitHub {
    owner = "istio";
    repo = "istio";
    rev = "a0b1b397d9637a3308e0373d6df9ac3b5974a790";
    sha256 = "1mdfsgp03x1bv55zzpsqjlzvnyamgpy70z8vwy17wpa04v74l7qc";
  };

  knative-serving-json = helm.yaml-to-json rec {
    name = "knative-serving";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = "https://github.com/knative/serving/releases/download/v${version}/serving.yaml";
      sha256="1q2w8bgjy8l8g2ksi9xla7wwnja1kk1szrh8fzg8jypjkqs1lbmc";
    };
  };

  knative-eventing-json = helm.yaml-to-json rec {
    name = "knative-eventing";
    version = "0.9.0";
    src = pkgs.fetchurl {
      url = "https://github.com/knative/eventing/releases/download/v${version}/eventing.yaml";
      sha256="02y0hqa0wsf94has2x4ywxdjmyy3a0jg5v3rcn2c2cclmqs5psfl";
    };
  };

  knative-crd-json = helm.yaml-to-json {
    name = "knative-crd";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.8.1/serving-beta-crds.yaml;
      sha256="1q9w4j81rmpgjyi1j0jniavw10f852pnvrzwvdia6a00rn568plx";
    };
  };

  tekton-pipelines-json = helm.yaml-to-json {
    name = "tekton-pipelines";
    version = "0.7.0";
    src = pkgs.fetchurl {
      url = https://github.com/tektoncd/pipeline/releases/download/v0.7.0/release.yaml;
      sha256="051ahdzzaqbwxy04c6adlm29rh50pfngpd82jj1asv1py16bd19v";
    };
  };

  tekton-dashboard-json = helm.yaml-to-json {
    name = "tekton-dashboard";
    version = "0.1.1";
    src = pkgs.fetchurl {
      url = https://github.com/tektoncd/dashboard/releases/download/v0.1.1/release.yaml;
      sha256="1012v7p6myn9wjyynqry9rf1hx6s1xw38xp3kj6kw3gckwapj9j6";
    };
  };

  # FIXME filter out prometheus
  knative-monitoring-json = helm.yaml-to-json {
    name = "knative-monitoring";
    version = "0.8.1";
    src = pkgs.fetchurl {
      # without prometheus
      url = https://github.com/knative/serving/releases/download/v0.8.1/monitoring.yaml;
      sha256="02x8hy9wrlkdnl6mz01v0dh7msmmx12zph9lpwpy7lf8fjv87435";
    };
  };

  rook-ceph-toolbox = helm.yaml-to-json {
    name = "rook-ceph-toolbox";
    version = "1.0.5";
    src = pkgs.fetchurl {
      url = https://raw.githubusercontent.com/rook/rook/v1.0.5/cluster/examples/kubernetes/ceph/toolbox.yaml;
      sha256="1iic9dd4r0qw7rvlgakpdajhbkawp6al8bq1hclb11dfyr1gg136";
    };
  };
}
