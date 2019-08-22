# TODO should be handled similary to helm - don't need to have another pattern here
{lib, pkgs, kubenix}:
with kubenix.lib;
overridings: json:
  let
    altered-content = 
      builtins.toJSON
        (builtins.map 
          (x: lib.recursiveUpdate x overridings)
          (builtins.fromJSON (builtins.readFile json)));
  in
    pkgs.writeText "k8s-yaml-overriding" "${altered-content}"