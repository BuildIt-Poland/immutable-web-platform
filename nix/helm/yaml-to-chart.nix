{
  kubenix,
  pkgs,
  lib,
  stdenv,
  stdenvNoCC
}:
let
in
{
  name,
  src,
  chart ? "", 
  version ? null
}: stdenvNoCC.mkDerivation {
  inherit version src;

  buildCommand = ''
    mkdir -p $out
    helm create ${name}

    helm install --dry-run --debug ./${name}
  '';
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";

  nativeBuildInputs = [ kubernetes-helm gawk remarshal jq ];

  outputHash = sha256;
}