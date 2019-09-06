{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "istioctl-${version}";
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "istio";
    repo = "istio";
    rev = "${version}";
    sha256 = "1a98ljyn80ph672c7kqby9gl63g0pnbb0pr9c921gpdnpaqr4d1f";
  };

  goPackagePath = "github.com/istio/istio";
  modSha256 = "11vh78pp8yz91myrgcch73c371bbg6cglbvvaq7fl1bra5fdqij6";
  subPackages = ["istioctl/cmd/istioctl"];

  meta = with lib; {
    description = "An open platform to connect, manage, and secure microservices.";
    homepage = https://github.com/istio/istio;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}