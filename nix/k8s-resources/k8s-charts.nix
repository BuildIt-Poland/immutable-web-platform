{ kubenix }:
with kubenix.lib.helm;
rec {
  brigade = fetch {
    chart = "brigade";
    repo = "https://brigadecore.github.io/charts";
    version = "1.1.0";
    sha256 = "0is2iqgzinlrx46nz1w30m8f1ggpnhl8ybb2d01fwhhhyvfcd0si";
  };

  brigade-project = fetch {
    chart = "brigade-project";
    repo = "https://brigadecore.github.io/charts";
    version = "1.0.0";
    sha256 = "1mi4y5slj2pkbxf2dyckjsvj647ip9zaqkmp9cjfwq4b1gnpnd0h";
  };

  brigade-bitbucket = chart-from-git {
    url = https://github.com/lukepatrick/brigade-bitbucket-gateway;
    sha256 = "15hvrk90wkycqbdnir0w74a3ghl6s26cfd9rl7aj2wmxga0vdc48";
    rev = "bc7889c4898d75921fdc46186731e9d934236861";
    path = "charts/brigade-bitbucket-gateway";
  };

  istio = fetch {
    chart = "istio";
    version = "1.2.4";
    repo = "https://storage.googleapis.com/istio-release/releases/1.2.4/charts";
    sha256 = "12vrxf63ghdq8x2xrjc392ib36cakix5rd5yx9rwrg38vs1n6vmw";
  };

  weave-scope = fetch {
    chart = "stable/weave-scope";
    version = "1.1.2";
    sha256 = "0lh1p5gy3cf3yac2kvrg925aig22b4bn8249j8ak70qvc3q02zsm";
  };

  docker-registry = fetch {
    chart = "stable/docker-registry";
    version = "1.8.0";
    sha256 = "1zz4xl2z6gllkg40rqvn1gm9aj49iz9ja9lvs8n7rlbqqkixqra9";
  };

  grafana = fetch {
    chart = "stable/grafana";
    version = "3.8.7";
    sha256 = "0i4b3yg5yjjhn34p9lxgbldcnbhr31cfgzn7m6n7nz5kdlz520bp";
  };

  kibana = fetch {
    chart = "stable/kibana";
    version = "3.2.3";
    sha256 = "0x3cac61zqnmbrid1m4q4l55zglw8w320dq3i7yccw92fkcdcfw8";
  };

  elastic-stack = fetch {
    chart = "stable/elastic-stack";
    version = "1.8.0";
    sha256 = "0c61c5kgb367kik74jxrzk62s526fva3qwdlia95dhk3iw72fl8z";
  };

  rook-ceph = fetch {
    chart = "rook-ceph";
    version = "1.0.5";
    repo = "https://charts.rook.io/release";
    sha256 = "0zza206wagv6fabmj7zr0zjpjn44hadb2qn3v3hk8wyvi5ylzhib";
  };

  # Backups
  velero = fetch {
    chart = "stable/velero";
    version = "2.1.4";
    sha256 = "1inhi72jk87xxl1ld95d96kahgzmjn5k77i7p8plxb4g0bjkc8ks";
  };

  external-dns = fetch {
    chart = "stable/external-dns";
    version = "2.5.4";
    sha256 = "1zdlm3h3nx59svaksq3f2skfv5hkv4lpdp2v0zj3v0b5yffsk68f";
  };

  cert-manager = fetch {
    chart = "cert-manager";
    version = "0.8.1";
    sha256 = "1c7y2q2rp1b4jmmblkbgvr8p25i7jsq8dya2qjr0sg158kcji3f2";
    repo = "https://charts.jetstack.io";
  };

  # https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd
  argo-cd = chart-from-git {
    url = "https://github.com/argoproj/argo-helm";
    path = "charts/argo-cd";
    rev = "77e638f55df69450b887087e5103bcae90db6fee";
    sha256 = "0z1byb135402j2x9swci7pcdcjpfzchc8j16dwj0zbfxmw1nbmwi";
  };

  # BOOTSTRAP
  istio-init = fetch {
    chart = "istio-init";
    version = "1.2.4";
    repo = "https://storage.googleapis.com/istio-release/releases/1.2.4/charts";
    sha256 = "04fw22zxsq9r0f9724ycv9k5x1f5jyhwf18zfk0y5i53cy0amysx";
  };

  istio-init-json = values: chart2json {
    inherit values;

    name = "istio-init";
    chart = istio-init;
  };

  # AWS related
  kube2iam = fetch {
    chart = "stable/kube2iam";
    version = "2.0.1";
    sha256 = "0xj22mkhripa3pd4fd02i05q3v7wyhhfk2bmf8x7927bsjr35wb4";
  };

  cluster-autoscaler = fetch {
    chart = "stable/cluster-autoscaler";
    version = "3.2.0";
    sha256 = "0wmx7wfg3s4s4hbq6qq85s0n6408yqgnwyzwyjwbznkl54xyslak";
  };

}