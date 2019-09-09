{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "kn-${version}";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "knative";
    repo = "client";
    rev = "v${version}";
    sha256 = "0bixbf7xbq3n1h4vwmcxz28avnl8gh8qrjiqll2wpdgfxb0y9pzc";
  };

  goPackagePath = "github.com/knative/client";
  modSha256 = "11wxyps4a2f9m4j9arcvk30vaha89qx4dzn5msbw91053hdp0hd8";

  meta = with lib; {
    description = "Knative CLI";
    homepage = https://github.com/knative/client;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}