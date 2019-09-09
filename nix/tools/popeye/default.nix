{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "popeye-${version}";
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "derailed";
    repo = "popeye";
    rev = "v${version}";
    sha256 = "0mj78mil6lz5s9b5ddkljnf53vjgh50byhiw5fhmgnk02srxhdkd";
  };

  goPackagePath = "github.com/derailed/popeye";
  modSha256 = "1qq4ixd8wk4jwq62hv26lw8w1y5jjds3rijgp3hr0h624s5imcq9";

  patches = [
    ./thrift.patch 
  ];

  meta = with lib; {
    description = "Popeye is a utility that scans live Kubernetes cluster and reports potential issues with deployed resources and configurations.";
    homepage = https://github.com/derailed/popeye;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}