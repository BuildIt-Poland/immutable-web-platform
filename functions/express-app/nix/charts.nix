{ env-config, kubenix }:
with kubenix.lib.helm;
let
  inherit (kubenix.lib.helm) fetch;
in
rec {
  mongodb-chart = fetch {
    chart = "stable/mongodb";
    version = "5.17.0";
    sha256 = "095kjm629rpnzpa8118nl8523pyvk433mj0icxysvpq6667pbphv";
  };
}