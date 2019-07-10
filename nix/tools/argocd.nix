{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "1.1.0-rc5";
  bin-name = "argocd";
  os = if isDarwin then "darwin" else "linux";
in
mkDerivation rec {
  inherit version;

  name = "argocd";

  src = pkgs.fetchurl {
    url = "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-${os}-amd64";
    sha256 = "06qyh7xqa981f7vypsv3pkz3i6jx2irhvchz8nfni224kms3j858"; # sha for linux will be different
  };

  buildInputs = [ ];
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${bin-name}
    chmod +x $out/bin/${bin-name}
  '';
}

