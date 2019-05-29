# TODO use buildGoPackage
{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "0.11.1";
  getSource = {version, os}: pkgs.fetchurl {
    url = "https://github.com/slok/brigadeterm/releases/download/v${version}/brigadeterm-${os}-amd64";
    sha256 = "076d32rcz56q58n8cy2r8qdycasgkh0hb05i736g5q60b793n5cy";
  };
in
mkDerivation rec {
  name = "knctl";
  inherit version;

  src = 
    if isDarwin
      then getSource {inherit version; os = "darwin";}
      else getSource {inherit version; os = "linux";};

  buildInputs = [ ];
  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/brigadeterm
    chmod +x $out/bin/brigadeterm
  '';
}

