{lib, pkgs, kubenix}:
with kubenix.lib;
jsons:
  toYAML (k8s.mkHashedList { items = jsons; })