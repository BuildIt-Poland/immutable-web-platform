{ pkgs, writeShellScript }:
with pkgs.stdenv;
# INFO before moving to 0.3.0 instead of tar.gz we need to have tar
# for now option is to, create local docker repository (not a big fan),
# or do a docker load < *.tar.gz, and then docker save sth:sth -o image.tar

# INFO 0.3.0 - from what they said in docs it should be faster - however I don't see that way
# when I'm exporting the same image timmings are the same, most likely realated to
# https://github.com/kubernetes-sigs/kind/pull/382 
# 
let
  version = "0.4.0";
  # version = "0.3.0";
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

