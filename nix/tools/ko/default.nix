{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "ko-${version}";
  version = "0.master.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "ko";
    rev = "15f971997010532913bf870a3af8b5775954f36c";
    sha256 = "0rk6vcg8qlwh7q3396cscfssws7kv17yl21vv4n98izbmnfj2p4m";
  };

  subPackages = ["cmd/ko"];

  goPackagePath = "github.com/google/ko";
  modSha256 = "1kvbi6k1ybvfll23niyg2c0nrmpjag2nhjxmy7mm95l7wgbacmvk";

  meta = with lib; {
    description = "ko is a tool for building and deploying Golang applications to Kubernetes.";
    homepage = https://github.com/google/ko;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}