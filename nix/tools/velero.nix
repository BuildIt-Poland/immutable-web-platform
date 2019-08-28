{ pkgs, writeShellScript }:
with pkgs.stdenv;
assert isDarwin; # sha for linux will be different
let
  name = "velero";
  version = "1.1.0";
  os = "osx";
  filename = "${name}-v${version}-darwin-amd64";
in
mkDerivation rec {
  inherit version name;

  src = pkgs.fetchurl {
    url = "https://github.com/heptio/velero/releases/download/v${version}/${filename}.tar.gz";
    sha256 = "029flflq9ha20q00l2sbydw1pb0z683b0h1r508x91kfapwq7rf4"; # sha for linux will be different
  };

  buildInputs = [ ];
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    tar xf $src -C .
    cp -r ./${filename}/* $out/bin/
    chmod -R +x $out/bin
  '';
}

