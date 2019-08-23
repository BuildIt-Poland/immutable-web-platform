# TODO should be handled similary to helm - don't need to have another pattern here
{lib, pkgs, kubenix}:
with kubenix.lib;
overridings: json-file:
  let
    json = builtins.fromJSON (builtins.readFile json-file);
    altered-content = 
      builtins.toJSON
        (builtins.map 
          # FIXME this should be smarter - check if exists if so change
          # https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix#L393
          (x: lib.recursiveUpdate x overridings)
          json);
  in
    pkgs.writeText "k8s-yaml-overriding" "${altered-content}"