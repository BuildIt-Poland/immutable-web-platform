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

  knative-serving-json = helm.yaml-to-json {
    name = "knative-serving";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.8.1/serving.yaml;
      sha256="1q2w8bgjy8l8g2ksi9xla7wwnja1kk1szrh8fzg8jypjkqs1lbmc";
    };
  };

  knative-crd-json = helm.yaml-to-json {
    name = "knative-crd";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.8.1/serving-beta-crds.yaml;
      sha256="17gcn52nch295sxy0lf2qr1alprj3jvnhm45v3yipxqr3jbcsw3x";
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
