{ env-config, kubenix }:
let
  inherit (kubenix.lib.helm) chart2json fetch;
in
rec {
  mongodb-chart = fetch {
    chart = "stable/mongodb";
    version = "5.17.0";
    sha256 = "095kjm629rpnzpa8118nl8523pyvk433mj0icxysvpq6667pbphv";
  };

  mongodb-json = chart2json {
    name = "mongodb";
    chart = mongodb-chart;
    namespace = env-config.helm.namespace;
    values = {
      # https://github.com/helm/charts/blob/master/stable/mongodb/values.yaml
      usePassword = false;
    };
  };
}