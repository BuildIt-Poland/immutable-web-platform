{lib, pkgs, kubenix, k8s-resources}:
with pkgs;
with kubenix.lib;
rec {

  knative-serving-json = helm.yaml-to-json {
    name = "knative-serving";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/serving.yaml;
      sha256="177aq85d8933p9rby10v2g72sgs2a60q675qr1im55f1acf19llz";
    };
  };

  knative-crd-json = helm.yaml-to-json {
    name = "knative-crd";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/serving-beta-crds.yaml;
      sha256="13ns3sc857qqipjdfdbjgcaj1sfkyspbv9dwvdw7jp91rlr73qrf";
    };
  };
  
  knative-monitoring-json = helm.yaml-to-json {
    name = "knative-monitoring";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.7.1/monitoring.yaml;
      sha256="0cdpp1d3k39vghn5m6l6cxpqz5k935r1x4fq16k62ssnick3p0ss";
    };
  };

  # core crd
  cert-manager-crd-json = helm.yaml-to-json {
    name = "cert-manager-crd";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml;
      sha256 = "1a1sgh32x4ysf1mkdw4x8j5jj7xdcqcmw9a7h5qfpkl2yvn0cl18";
    };
  };

}
