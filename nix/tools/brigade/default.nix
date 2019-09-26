{ lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "brigade-${version}";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "brigadecore";
    repo = "brigade";
    rev = "v${version}";
    sha256 = "0jcfgg74c9jliskijamidr71ysv9cpk4yabdpcfsjq6nbrni82pr";
  };

  goDeps = ./deps.nix;
  doCheck = false;
  goPackagePath = "github.com/brigadecore/brigade";
  modSha256 = "0a00kcyagqczw0vhl8qs2xs1y8myw080y9kjs4qrcmj6kibdy55q";

  meta = with lib; {
    description = "Script simple and complex workflows using JavaScript. Chain together containers, running them in parallel or serially. Fire scripts based on times, GitHub events, Docker pushes, or any other trigger. Brigade is the tool for creating pipelines for Kubernetes.";
    homepage = https://github.com/brigadecore/brigade;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}