{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "1.0.0";
  getSource = {version, os}: pkgs.fetchurl {
    url = "https://github.com/brigadecore/brigade/releases/download/v${version}/brig-darwin-amd64";
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

  buildInputs = [ ];
  phases = ["installPhase"];
    # cp ${curl-with-hosts} $out/bin/${curl-with-hosts.name}
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/knctl
    ls $out/bin
    chmod +x $out/bin/knctl
  '';
}
