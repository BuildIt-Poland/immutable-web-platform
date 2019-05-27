{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "1.0.0";
  getSource = {version, os}: pkgs.fetchurl {
    url = "https://github.com/brigadecore/brigade/releases/download/v${version}/brig-${os}-amd64";
    sha256 = "1h9smrrlvmkg91gnmiby5dmsac99xnxprjlddb615wzdwb1pr9ps";
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
    cp $src $out/bin/brigade
    chmod +x $out/bin/brigade
  '';
}
