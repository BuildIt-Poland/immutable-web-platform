{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "brigadeterm-${version}";
  version = "0.11.1";

  src = fetchFromGitHub {
    owner = "slok";
    repo = "brigadeterm";
    rev = "v${version}";
    sha256 = "03n748y2y5qd5v5wyk88719ksjqqjiavj1qlgg05z84q7mbm09am";
  };

  goPackagePath = "github.com/slok/brigadeterm";
  modSha256 = "0gskc150h70w7ssp31wik3r8kfnf0s9p1jbnb1fcyz2lmzhwqq2d";

  meta = with lib; {
    description = "Brigadeterm is a text based dashboard for Brigade pipeline system.";
    homepage = https://github.com/slok/brigadeterm;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}