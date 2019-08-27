{lib, pkgs, kubenix, k8s-resources}:
with pkgs;
with kubenix.lib;
rec {

  knative-serving-json = helm.yaml-to-json {
    name = "knative-serving";
    version = "0.8.0";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.8.0/serving.yaml;
      sha256="1s4qdp9cikv1sjzw0xzxwzad2431cv5zp816nqbwfpcq1j0fham7";
    };
  };

  knative-crd-json = helm.yaml-to-json {
    name = "knative-crd";
    version = "0.8.0";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.8.0/serving-beta-crds.yaml;
      sha256="17gcn52nch295sxy0lf2qr1alprj3jvnhm45v3yipxqr3jbcsw3x";
    };
  };
  
  knative-monitoring-json = helm.yaml-to-json {
    name = "knative-monitoring";
    version = "0.8.0";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.8.0/monitoring.yaml;
      sha256="0b37rv8a3ck8qx7a01nyjj5w0wf82yayw2a95dgi67vahdq84gjf";
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
