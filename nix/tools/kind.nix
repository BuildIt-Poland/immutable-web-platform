{ pkgs, writeShellScript }:
with pkgs.stdenv;
assert isDarwin; # sha for linux will be different
let
  version = "0.4.0";
  bin-name = "kind";
  os = if isDarwin then "darwin" else "linux";
in
mkDerivation rec {
  inherit version;

  name = "kind";

  src = pkgs.fetchurl {
    url = "https://github.com/kubernetes-sigs/kind/releases/download/v${version}/kind-${os}-amd64";
    sha256 = "1lyjx6vzdmiickncj01bfc8959w8jkq8d6hkcbydqcki4231hgq2";
  };

  buildInputs = [ ];
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${bin-name}
    chmod +x $out/bin/${bin-name}
  '';
}

