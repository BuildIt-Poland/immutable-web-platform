{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "restic-${version}";
  version = "0.9.5";

  src = fetchFromGitHub {
    owner = "restic";
    repo = "restic";
    rev = "v${version}";
    sha256 = "1bhn3xwlycpnjg2qbqblwxn3apj43lr5cakgkmrblk13yfwfv5xv";
  };

  subPackages = ["cmd/restic"];
  goPackagePath = "github.com/restic/restic";
  modSha256 = "1xgzvh8dvjpmqxjk61bl29rqldy0q5ggxg2jgy2k8wglrd0qmfmj";

  patches = [
    ./thrift.patch 
  ];

  meta = with lib; {
    description = "Restic is a backup program that is fast, efficient and secure. It supports the three major operating systems (Linux, macOS, Windows) and a few smaller ones (FreeBSD, OpenBSD).";
    homepage = https://github.com/restic/restic;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}