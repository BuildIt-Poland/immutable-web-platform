{
  kubenix,
  writeText
}:
with kubenix.lib.helm;
rec {
  brigade = rec {
    chart = fetch {
      chart = "brigade";
      repo = "https://brigadecore.github.io/charts";
      version = "1.0.0";
      sha256 = "0i5i3h346dz4a771zkgjpbx4hbyf7r6zfhvqhvfjv234dha4fj50";
    };

    # https://github.com/xtruder/kubenix/blob/kubenix-2.0/lib/helm/chart2json.nix
    json = chart2json {
      inherit chart;
      name = "brigade";
      values = {};
    };
    # lib.importJSON

    # https://github.com/brigadecore/charts/blob/master/charts/brigade/values.yaml
    config = { };

    values = writeText "brigade-config.json" 
      (builtins.toJSON  config);
  };
}