{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "restic-${version}";
  version = "0.9.4";

  src = fetchFromGitHub {
    owner = "restic";
    repo = "restic";
    rev = "v${version}";
    sha256 = "15lx01w46bwn3hjwpmm8xy71m7ml9wdwddbbfvmk5in61gv1acr5";
  };

  goPackagePath = "github.com/restic/restic";
  modSha256 = "0sgdvvl2cc1wbw30b4i4xhh8h7pa2br85lcx381hm75fg2m7lxim";

  meta = with lib; {
    description = "Restic is a backup program that is fast, efficient and secure. It supports the three major operating systems (Linux, macOS, Windows) and a few smaller ones (FreeBSD, OpenBSD).";
    homepage = https://github.com/restic/restic;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}