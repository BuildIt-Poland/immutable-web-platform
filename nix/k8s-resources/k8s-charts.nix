{ kubenix }:
with kubenix.lib.helm;
rec {
  brigade = fetch {
    chart = "brigade";
    repo = "https://brigadecore.github.io/charts";
    version = "1.1.0";
    sha256 = "0sw3g0c17klmqfzdal41916wxm90l53ki379vdngc388xk17251r";
  };

  brigade-project = fetch {
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

  istio = fetch {
    chart = "istio";
    version = "1.2.4";
    repo = "https://storage.googleapis.com/istio-release/releases/1.2.4/charts";
    sha256 = "1h269yj9whc49yiyqgzaz77nz2viwxillc1y3r9y507lk5wfg9m1";
  };

  weave-scope = fetch {
    chart = "stable/weave-scope";
    version = "1.1.2";
    sha256 = "0x7nas78jj517znx448wsgzin70nzd91j7961zk9lnmjha5jxa0m";
  };

  docker-registry = fetch {
    chart = "stable/docker-registry";
    version = "1.8.0";
    sha256 = "1dh23bryfh30p1r4b6pz9qgfniyji9nsn238ab2g2l3pwcvjb1zc";
  };

  rook-ceph = fetch {
    chart = "rook-ceph";
    version = "1.0.5";
    repo = "https://charts.rook.io/release";
    sha256 = "0136briq1aw36l25sbv8337al9a7x1bx1m3by78q5dsg4dk4rbl1";
  };

  external-dns = fetch {
    chart = "stable/external-dns";
    version = "2.5.4";
    sha256 = "1s7474ip77j06y8hmlh592rhgvbmyqy8mvpcp7jwsxd3xipahmiv";
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
    rev = "c7b415b6341b9db6c57e3d378e2d98ec493bfbe5";
    sha256 = "0llvh6x04pglv3m7frc7a0xbchkfz9zkg2kj0msnisjbs2x2c1dn";
  };

  # BOOTSTRAP
  istio-init = fetch {
    chart = "istio-init";
    version = "1.2.4";
    repo = "https://storage.googleapis.com/istio-release/releases/1.2.4/charts";
    sha256 = "1jpyfq4v6rp9l7jd2dcn0xdd6rrbkmxgzcr0q51r6fbcysvp0bwr";
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
    sha256 = "1c4dw9681p8gkapwgmvhdgrhh5x1f94lqhc1rl050wv993zzqy2g";
  };

  cluster-autoscaler = fetch {
    chart = "stable/cluster-autoscaler";
    version = "3.2.0";
    sha256 = "1vqcdd186csknkz0dsrm1mvbpiqhd4wjnz61sx0vpdg8l5lrkb13";
  };

}