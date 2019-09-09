{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "krew-${version}";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "krew";
    rev = "v${version}";
    sha256 = "1flfrg01g2hy5k0y3d4gfkllj28apw48l7bx4x2b9klixn29p11p";
  };

  subPackages = ["cmd/krew"];
  goPackagePath = "github.com/kubernetes-sigs/krew";
  modSha256 = "0px1msr15s3z07jc2dgg692vr79a2q978r8drq3wd2zbghhsc88n";

  postInstall = ''
    cp $out/bin/krew $out/bin/kubectl-krew
  '';

  meta = with lib; {
    description = "krew is the package manager for kubectl plugins.";
    homepage = https://github.com/kubernetes-sigs/krew;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}