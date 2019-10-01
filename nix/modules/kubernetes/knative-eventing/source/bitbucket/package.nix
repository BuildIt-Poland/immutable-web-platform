{pkgs}:
with pkgs;
  subPackages: (buildGoModule rec {
    inherit subPackages;

    name = "bitbucket-source-${version}";
    version = "master";
    rev = "07ca52cf41455e0811f3f053c7577c6f5047af4b";

    src = fetchFromGitHub {
      inherit rev;
      owner = "damianbaar";
      repo = "bitbucket-source";
      sha256 = "1gqj6al4j79kigyp17qh3dx6v6kb6wnpw1vf333jh312dh14wmh6";
    };

    goPackagePath = "github.com/damianbaar/bitbucket-source";
    modSha256 = "168pydyvym66cckrxgvmgrvds1gj2df5p28mr9xygaql7gzp2cci";

    meta = with lib; {
      description = "This repository implements a simple Event Source to wire BitBucket events into Knative Eventing.";
      homepage = https://github.com/damianbaar/bitbucket-source;
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  })