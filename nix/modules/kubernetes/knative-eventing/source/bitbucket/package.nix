{pkgs}:
with pkgs;
  subPackages: (buildGoPackage rec {
    inherit subPackages;

    name = "bitbucket-source-${version}";
    version = "master";
    rev = "134b01b95b8ccb38e903b7ceb17d7e0e58cfd3bb";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nachocano";
      repo = "bitbucket-source";
      sha256 = "0d0w530am30ndd33kcw1y1wqp8pn8xhzszm0zb36rwwwmin3cybp";
    };

    buildInputs = [ ];

    goDeps = ./deps.nix;
    goPackagePath = "github.com/nachocano/bitbucket-source";
    modSha256 = "06cxpsdbmynpprxnaq8ciplan2ha61vmlqzp5q2bmd9r0palh7p3";

    meta = with lib; {
      description = "This repository implements a simple Event Source to wire BitBucket events into Knative Eventing.";
      homepage = https://github.com/nachocano/bitbucket-source;
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  })