# TODO - align correct revisions and deps
{ lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "argocd-${version}";
  version = "1.1.0-rc5";

  src = fetchFromGitHub {
    owner = "argoproj";
    repo = "argo-cd";
    rev = "v${version}";
    sha256 = "099cria8zvlrxdxfzx5b68sccv01j3ha9bhbyxxczlpkckdsd801";
  };

  goDeps = ./deps.nix;
  goPackagePath = "github.com/argoproj/argo-cd";

  meta = with lib; {
    description = "Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.";
    homepage = https://github.com/argoproj/argo-cd;
    license = licenses.asl20;
    maintainers = with maintainers; [ groodt ];
    platforms = platforms.unix;
  };
}