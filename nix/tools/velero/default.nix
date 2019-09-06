{ pkgs, lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "velero-${version}";
  version = "1.1.0";
  rev = "v${version}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "heptio";
    repo = "velero";
    sha256 = "0k2rcmq2v8sjrzhgqpvnqdw8as26jhsvf4cym80cyzvdlyh65zi0";
  };

  goDeps = ./deps.nix;
  goPackagePath = "github.com/heptio/velero";

  modSha256 = "0a00kcyagqczw0vhl8qs2xs1y8myw080y9kjs4qrcmj6kibdy55q";

  meta = with lib; {
    description = "Velero gives you tools to back up and restore your Kubernetes cluster resources and persistent volumes.";
    homepage = https://github.com/heptio/velero;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}