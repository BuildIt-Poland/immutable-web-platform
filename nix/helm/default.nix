{
  kubenix,
  pkgs,
  lib,
  stdenv,
  stdenvNoCC
}:
let
  cleanName = name: lib.replaceStrings ["/"] ["-"] name;
in
{
  chart ? "", 
  path, 
  url, 
  sha256,
  rev,
  version ? null
}: stdenv.mkDerivation {
  inherit version;

  name = "${cleanName chart}-${if version == null then "dev" else version}";

  src = pkgs.fetchgit {
    inherit url sha256 rev;
  };

  buildCommand = ''
    mkdir -p $out
    cp -av $src/${path}/* $out
  '';
}