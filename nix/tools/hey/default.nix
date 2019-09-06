{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "hey-${version}";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "rakyll";
    repo = "hey";
    rev = "v${version}";
    sha256 = "02p0gaf28gbfg7kixm35yn1bbzv6pr28bhjbp4iz9qd5221hfpbj";
  };

  goPackagePath = "github.com/rakyll/hey";
  modSha256 = "0a00kcyagqczw0vhl8qs2xs1y8myw080y9kjs4qrcmj6kibdy55q";

  meta = with lib; {
    description = "hey is a tiny program that sends some load to a web application";
    homepage = https://github.com/rakyll/hey;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}