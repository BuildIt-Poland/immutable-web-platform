{
  kubenix,
  chart-from-git,
  lib
}:
let 
in
with kubenix.lib;
rec {
  brigade = helm.fetch {
    chart = "brigade";
    repo = "https://brigadecore.github.io/charts";
    version = "1.0.0";
    sha256 = "0i5i3h346dz4a771zkgjpbx4hbyf7r6zfhvqhvfjv234dha4fj50";
  };

  brigade-project = helm.fetch {
    chart = "brigade-project";
    repo = "https://brigadecore.github.io/charts";
    version = "1.0.0";
    sha256 = "05q4vvl1h79xd5xk44x29dq3y2a06pjvan355qzh5xga1jiga934";
  };

  brigade-bitbucket = chart-from-git {
    url = https://github.com/damianbaar/brigade-bitbucket-gateway;
    sha256 = "00vk1ywnkxihp3gqfkn7j641lgx353dkl7gbfsbkanc8rzdjbs5j";
    path = "charts/brigade-bitbucket-gateway";
  };

  istio = helm.fetch {
    chart = "istio";
    version = "1.1.9";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.9/charts";
    sha256 = "1ly6nd4y9shvx166pbpm8gmh0r1pn00d5y4arxvxb5rqbsdknzjh";
  };

  nginx-ingress = helm.fetch {
    chart = "stable/nginx-ingress";
    version = "1.7.0";
    sha256 = "12kal4q07al25wz9j1422sn2zg8icj1csznch64vgci38h6m06vd";
  };

  weave-scope = helm.fetch {
    chart = "stable/weave-scope";
    version = "1.1.2";
    sha256 = "0x7nas78jj517znx448wsgzin70nzd91j7961zk9lnmjha5jxa0m";
  };

  knative-serving = yaml-to-json {
    name = "knative-serving";
    version = "0.6.1";
    src = pkgs.fetchurl {
      url = https://github.com/knative/serving/releases/download/v0.6.1/serving.yaml;
      sha256="0y9h2mw1f2rbhmv2qfsz2m2cppa1s725i9hni5105s3js07h0r0i";
    };
  };

  istio-cni = helm.fetch {
    chart = "istio-cni";
    version = "0.1.0";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.9/charts";
    sha256 = "1qb2qx088bwf6pv4xay0bbdqkjk1i0cmgjvn0xsxjb1z7x7xy01d";
  };

  istio-cni-json = helm.chart2json {
    name = "istio-cni";
    namespace = "kube-system"; # TODO
    chart = istio-cni;
  };

  istio-cni-yaml = toYAML (k8s.mkHashedList { 
    items = 
      (lib.importJSON istio-cni-json);
  });

  istio-json = helm.chart2json {
    name = "istio";
    chart = istio;
  };

  istio-init = helm.fetch {
    chart = "istio-init";
    version = "1.1.9";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.9/charts";
    sha256 = "1vdsxrz4gis5za519p0zjmd9zjckjaa34pdssbn9lis19x20ki7v";
  };

  istio-init-json = helm.chart2json {
    name = "istio-init";
    chart = istio-init;
  };

  istio-init-yaml = toYAML (k8s.mkHashedList { 
    items = 
      (lib.importJSON istio-init-json);
  });
}