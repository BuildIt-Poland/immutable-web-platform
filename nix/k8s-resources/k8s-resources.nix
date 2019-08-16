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
