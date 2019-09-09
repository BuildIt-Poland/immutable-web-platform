{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "dig-${version}";
  version = "develop";

  src = fetchFromGitHub {
    owner = "sysdiglabs";
    repo = "kubectl-dig";
    rev = "3f0dfedb733d19c5633103b316927a936eab9565";
    sha256 = "1nvfsmr12vb3zidc9j31f6bsrpbf9vfps85pn9i1f10bpww53fw1";
  };

  subPackages = ["cmd/kubectl-dig"];
  goPackagePath = "github.com/sysdiglabs/kubectl-dig";
  modSha256 = "1g3mgnip70gmzpmdyin6jc8bfbhh2pahf5xn52yv194wjamkm4cr";

  meta = with lib; {
    description = "Deep kubernetes visibility from the kubectl.";
    homepage = https://github.com/sysdiglabs/kubectl-dig;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}