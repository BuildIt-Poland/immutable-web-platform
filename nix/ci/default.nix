{ stdenv, arion }: 
stdenv.mkDerivation {
  name = "concourse-ci-docker-compose";
  src = ./.;
  buildInputs = [arion];
  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}