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
    version = "0.9.0";
    src = pkgs.fetchurl {
      url = "https://github.com/knative/serving/releases/download/v${version}/serving.yaml";
      sha256="0mpca1fvh3phmym1vapn6ayf21w22srm1qrv7y9r019znmpyxzgc";
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

  knative-eventing-bitbucket-source-json = helm.yamls-to-json rec {
    name = "knative-eventing";
    version = "0.9.0";
    yamlsPattern = "/config/*.yaml";
    src = pkgs.fetchFromGitHub {
      owner = "nachocano";
      rev = "134b01b95b8ccb38e903b7ceb17d7e0e58cfd3bb";
      repo = "bitbucket-source";
      sha256="0d0w530am30ndd33kcw1y1wqp8pn8xhzszm0zb36rwwwmin3cybp";
    };
  };

  knative-crd-json = helm.yaml-to-json rec {
    name = "knative-crd";
    version = "0.9.0";
    src = pkgs.fetchurl {
      url = "https://github.com/knative/serving/releases/download/v${version}/serving-v1-crds.yaml";
      sha256="1f7pjag9zqqbaj8ycl5k4m66izzkkiw8wg9vjpfrr8fq1gjldfcb";
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

  knative-monitoring-json = helm.yaml-to-json rec {
    name = "knative-monitoring";
    version = "0.9.0";
    src = pkgs.fetchurl {
      url = "https://github.com/knative/serving/releases/download/v${version}/monitoring.yaml";
      sha256="0mllfg5a75yyiiimjnh2fcqi9krqn7y4mfq3kvry3jmiyym9ygx9";
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
