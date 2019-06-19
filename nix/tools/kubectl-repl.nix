# https://github.com/Mikulas/kubectl-repl
{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "1.7";
  name = "kubectl-repl";
  owner = "Mikulas";

  os = if isDarwin
    then "darwin"
    else "linux";

  src = pkgs.fetchurl {
    url = "https://github.com/${owner}/${name}/releases/download/${version}/${name}-${os}-amd64-${version}";
    sha256 = "0qgjzxbf4gjg1z9mpqwb8z52gvm0wk1862l4jghks2gdvx6w733l";
  };
in
mkDerivation rec {
  inherit 
    version 
    name 
    src;

  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
    chmod +x $out/bin/${name}
  '';
}
