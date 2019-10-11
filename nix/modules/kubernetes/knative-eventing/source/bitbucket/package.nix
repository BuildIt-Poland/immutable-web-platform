{pkgs}:
with pkgs;
let
  bb = pkgs.sources.bitbucket-source;
in
  subPackages: (buildGoModule rec {
    inherit subPackages;

    name = "bitbucket-source-${version}";
    version = bb.rev;
    rev = bb.rev;

    src = bb;

    goPackagePath = "github.com/damianbaar/bitbucket-source";
    modSha256 = "1d1qp0nyd7c5z76gbw36llhlq4fz4sp7a7wx3b8d3nwf9jlhqjgi";

    meta = with lib; {
      description = "This repository implements a simple Event Source to wire BitBucket events into Knative Eventing.";
      homepage = https://github.com/damianbaar/bitbucket-source;
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  })