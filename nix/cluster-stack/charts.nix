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
    version = "1.1.3";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.3/charts/index.yaml";
    sha256 = "1fm8l0nsmjiglfvrx9xqyzzz3jw1xpf4fy4radi1n51yjkp51lji";
  };

  istio-json = helm.chart2json {
    name = "istio";
    chart = istio;
  };

  istio-init = helm.fetch {
    chart = "istio-init";
    version = "1.1.3";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.3/charts";
    sha256 = "0znx8ixy0rvjvrkw5xw30i78qfzhq4jjm7k4n79mkv4z4am95wz5";
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