{
  kubenix,
  pkgs,
  chart-from-git
}:
let 
in
with kubenix.lib.helm;
rec {
  brigade = fetch {
    chart = "brigade";
    repo = "https://brigadecore.github.io/charts";
    version = "1.0.0";
    sha256 = "0i5i3h346dz4a771zkgjpbx4hbyf7r6zfhvqhvfjv234dha4fj50";
  };

  brigade-project = fetch {
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

  # INFO these below are not used yet
  # TODO they should work with helper from GIT so do it!
  istio-chart = fetch {
    chart = "istio";
    version = "1.1.0";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.0-rc.0/charts";
    sha256 = "0ippv2914hwpsb3kkhk8d839dii5whgrhxjwhpb9vdwgji5s7yfl";
  };

  istio-init-chart = fetch {
    chart = "istio-init";
    version = "1.1.0";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.0-rc.0/charts";
    sha256 = "1p86xkzqycpbgysdlzjbd6xspz1bmd4sb2667diln80qxwyv10fx";
  };
}