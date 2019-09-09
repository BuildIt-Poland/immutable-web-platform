{ lib, pkgs, fetchFromGitHub, buildGoPackage }:
with pkgs;
let
  version = "0.3.7";
  bin = buildGoPackage {
    inherit version;

    name = "gosu-${version}";

    src = fetchFromGitHub {
      owner = "aelsabbahy";
      repo = "goss";
      rev = "v${version}";
      sha256="1vfpdg7d4j8f7lgzlkkax2yyyaqvzibx2crrnbisbvjwvmj2np4g";
    };

    goDeps = ./deps.nix;

    subPackages = ["cmd/goss"];

    goPackagePath = "github.com/aelsabbahy/goss";
    modSha256 = "11vh78pp8yz91myrgcch73c371bbg6cglbvvaq7fl1bra5fdqijf";
  };
in 
stdenv.mkDerivation rec {
  inherit version;
  name = "dgoos-${version}";

  src = fetchFromGitHub {
      owner = "aelsabbahy";
      repo = "goss";
      rev = "6ba11dc982c498a54b7db9b35db0cad9e592ac1a";
      sha256 = "1qp5wqxp94rcp2hij0zhjb7qh7c6i19s18awgrkbrgwjz1fqc1zf";
    };

  phases = ["installPhase"];

  # FIXME wrapProgram with path would be better --prefix PATH : ${bin}/bin
  installPhase = ''
    mkdir -p $out/bin
    cp $src/extras/dgoss/dgoss $out/bin
    cp ${bin}/bin/goss $out/bin/goss
    chmod -R +rx $out/bin
  '';
}