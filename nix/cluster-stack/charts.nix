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
    url = https://github.com/lukepatrick/brigade-bitbucket-gateway;
    sha256 = "15hvrk90wkycqbdnir0w74a3ghl6s26cfd9rl7aj2wmxga0vdc48";
    rev = "bc7889c4898d75921fdc46186731e9d934236861";
    path = "charts/brigade-bitbucket-gateway";
  };

  istio = helm.fetch {
    chart = "istio";
    version = "1.2.1";
    repo = "https://storage.googleapis.com/istio-release/releases/1.2.1/charts";
    sha256 = "1w1yk2hz42q4iii2j22hb921sgnlw03iw48kpmgqn3b3ibbbwf0m";
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

  docker-registry = helm.fetch {
    chart = "stable/docker-registry";
    version = "1.8.0";
    sha256 = "1dh23bryfh30p1r4b6pz9qgfniyji9nsn238ab2g2l3pwcvjb1zc";
  };

  cert-manager = helm.fetch {
    chart = "cert-manager";
    version = "0.8.1";
    sha256 = "1c7y2q2rp1b4jmmblkbgvr8p25i7jsq8dya2qjr0sg158kcji3f2";
    repo = "https://charts.jetstack.io";
  };

  kube-registry-proxy = helm.fetch {
    chart = "kube-registry-proxy";
    version = "0.3.1";
    repo = "http://storage.googleapis.com/kubernetes-charts-incubator";
    sha256 = "04vnmyfqvddiw1n63sab4as7apcxq9gx0hrkv8p2w1b6q12hjwhd";
  };

  # https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd
  argo-cd = chart-from-git {
    # chart = "argo-cd";
    # version = "0.2.2";
    url = "https://github.com/argoproj/argo-helm";
    path = "charts/argo-cd";
    rev = "6e108f3aae4d5fa5788640f8bd8b3407e1425c13";
    sha256 = "0gsx75fcm4zinw1mqkpzs7vsivm7y52bfjhkc5mxfad61r725gr4";
  };

  # BOOTSTRAP

  istio-init = helm.fetch {
    chart = "istio-init";
    version = "1.2.1";
    repo = "https://storage.googleapis.com/istio-release/releases/1.2.1/charts";
    sha256 = "029bwi9p11x54lz0ik2cbny51hbmsavjyzk0m22a2wkjjvc0i3sr";
  };

  # TODO propagete this idea wider
  preload = [
    istio-init
    istio
    brigade
    brigade-project
    brigade-bitbucket
    weave-scope
    docker-registry 
    argo-cd
  ];

  istio-init-json = helm.chart2json {
    name = "istio-init";
    chart = istio-init;
  };

  istio-init-yaml = toYAML (k8s.mkHashedList { 
    items = 
      (lib.importJSON istio-init-json);
  });
}