# https://github.com/Mikulas/kubectl-repl
{ pkgs, writeShellScript }:
with pkgs.stdenv;
let
  version = "0.1.2";
  name = "hey";
  owner = "rakyll";

  os = if isDarwin
    then "darwin"
    else "linux";

  src = pkgs.fetchurl {
    url = "https://storage.googleapis.com/jblabs/dist/${name}_${os}_v${version}";
    sha256 = "1k786i0kxxf0bq4kcbz7rzhr77dw1gvhzjbhwjfdxm2mvmrjnjhp";
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
