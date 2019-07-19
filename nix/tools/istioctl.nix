{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "1.1.9";
  os = if isDarwin then "osx" else "linux";
in
mkDerivation rec {
  inherit version;

  name = "argocd";

  src = pkgs.fetchurl {
    url = "https://github.com/istio/istio/releases/download/${version}/istio-${version}-${os}.tar.gz";
    sha256 = "13l7l9ykh7la5qca7nxmv8gm8g30xvjak3q62ib3yxq4q2jl1p6c"; # sha for linux will be different
  };

  buildInputs = [ ];
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    tar xf $src -C .
    cp -r ./istio-${version}/bin/* $out/bin/
    chmod -R +x $out/bin
  '';
}

