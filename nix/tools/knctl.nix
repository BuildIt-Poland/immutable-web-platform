{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "0.3.0";
  getSource = {version, os}: pkgs.fetchurl {
    url = "https://github.com/cppforlife/knctl/releases/download/v${version}/knctl-${os}-amd64";
    sha256 = "1fchz6c58mzrh6ly2c5lncpcmsyk9j9ljc9qsqrwpwyvixg0fbrq";
  };
  curl-with-hosts = writeShellScript "curl" ''

    echo "curl curl" 
  '';
in
mkDerivation rec {
  name = "knctl";
  inherit version;

  src = 
    if isDarwin
      then getSource {inherit version; os = "darwin";}
      else getSource {inherit version; os = "linux";};

  buildInputs = [ pkgs.k8s-local.curl-with-resolve ];
  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/knctl
    chmod +x $out/bin/knctl
  '';
}
