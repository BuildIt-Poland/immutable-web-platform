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
  version ? null
}: stdenvNoCC.mkDerivation {
  inherit version;

  name = "${cleanName chart}-${if version == null then "dev" else version}";

  src = pkgs.fetchgit {
    inherit url;
    inherit sha256;
  };

  buildCommand = ''
    mkdir -p $out
    cp -av $src/${path}/* $out
  '';
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = sha256;
}