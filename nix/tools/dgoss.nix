# TODO - align correct revisions and deps
{ lib, pkgs, fetchFromGitHub }:
with pkgs;
let
  version = "0.3.7";
  bin = 
    (pkgs.fetchurl {
      url = "https://github.com/aelsabbahy/goss/releases/download/v${version}/goss-linux-amd64";
      sha256="0nb068ncr17q0p48lni58wwyn6db6b6ljhz4ph9b8jbr5rzmqzrm";
    });
in 
stdenv.mkDerivation rec {
  inherit version;
  name = "dgoos-${version}";

  src = fetchFromGitHub {
      owner = "aelsabbahy";
      repo = "goss";
      rev = "6ba11dc982c498a54b7db9b35db0cad9e592ac1a";
      sha256 = "1qp5wqxp94rcp2hij0zhjb7qh7c6i19s18awgrkbrgwjz1fqc1zf";
    };

  phases = ["installPhase"];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/extras/dgoss/dgoss $out/bin
    cp ${bin} $out/bin/goss
    ls $out/bin
    chmod -R +rx $out/bin
  '';
}