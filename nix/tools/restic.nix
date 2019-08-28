{ pkgs, writeShellScript }:
with pkgs.stdenv;
assert isDarwin; # sha for linux will be different
let
  name = "restic";
  version = "0.9.5";
  os = "osx";
  filename = "${name}_${version}_darwin_amd64";
in
mkDerivation rec {
  inherit version name;

  src = pkgs.fetchurl {
    name = "${filename}";
    url = "https://github.com/restic/restic/releases/download/v${version}/${filename}.bz2";
    sha256 = "1bqwfg6ajlrp8c0zy0s3nh4vfx6zqs1r0f81kjvsj6xqc43ws7dz"; # sha for linux will be different
  };

  buildInputs = [ ];
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    bzip2 -d $src --stdout > $out/bin/restic
    chmod -R +x $out/bin
  '';
}

