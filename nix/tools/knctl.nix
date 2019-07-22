{ pkgs, writeShellScript }:
with pkgs.stdenv;
assert isDarwin; # sha for linux will be different
let
  version = "0.2.0";
  # TODO this hashes are not ok for linux variant - build from source!
  getSource = {version, os}: pkgs.fetchurl {
    url = "https://github.com/knative/client/releases/download/v${version}/kn-${os}-amd64";
    sha256 = "0q4yk20xq7wv9fcw7hdmgksvhg2g4bl49hjqqaidxihlcbajh87r";
  };
in
mkDerivation rec {
  name = "knctl";
  inherit version;

  src = 
    if isDarwin
      then getSource {inherit version; os = "darwin";}
      else getSource {inherit version; os = "linux";};

  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    KN=$out/bin/kn

    cp $src $KN
    chmod +x $KN

    mkdir -p $out/etc/bash_completion.d/
    $KN completion > $out/etc/bash_completion.d/kn-completion.bash
  '';
}
