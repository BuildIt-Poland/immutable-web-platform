{ env-config, kubenix }:
with kubenix.lib.helm;
let
  inherit (kubenix.lib.helm) fetch;
in
rec {
  mongodb-chart = fetch {
    chart = "stable/mongodb";
    version = "5.17.0";
    sha256 = "1jjbckk4xxma1fjgfng26p278jwip9p629ym8048cil4mpvcm4ry";
  };
}