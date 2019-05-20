{kubenix}:
with kubenix.lib.helm;
rec {
  brigade-chart = fetch {
    chart = "brigade";
    chartUrl = "https://github.com/brigadecore/charts";
    version = "3ac3d9cd4293848d10cfdbea048cff242b14e709";
    sha256 = "114p685i04jmmb5gs0zj15nf4nhn5zkiblk1xdqzvpj05s62vqqw";
  };

  brigade-json = chart2json {
    name = "brigade";
    chart = brigade-chart;
  };
}