{lib, pkgs, ...}:
{ overridings ? [], jsons ? [] }:
  (lib.foldl 
    lib.concat
    overridings
    ((builtins.map lib.importJSON jsons)))