# INFO: this package is in general tricky ... I'm taking source from github and making it as dependency
# INFO: as this works like a workspace it has to have the same dependencies with the same versions
{ pkgs }:
let
  brigade-source = pkgs.fetchFromGitHub {
    owner = "brigadecore";
    repo = "brigade";
    rev = "a24d1a9c328df7e14c493a97ff77c7fb3434a4cc";
    sha256 = "14dz8579pb1rlmz3jrsdh9phsyrkrv3rld6s0pkxlwl382f578m0";
  };
  # INFO version with space ... good job ... https://github.com/brigadecore/brigade/blob/master/brigade-worker/package.json#L3
  # TODO need to provide a PR for it as it is super silly
  # INFO it is a bit awkward that this lib is not published 
  fixed-source = pkgs.stdenv.mkDerivation {
    name = "brigade-worker-base";
    src = "${brigade-source}/brigade-worker";
    phases = ["installPhase"];
    buildInputs = [pkgs.yarn];
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      sed  -i '/version/s/[^.]*$/'"0\",/" $out/package.json
      cd $out && yarn
    '';
  };

in
{ 
  # filter source here since there is a whole repo ...
  # base = pkgs.yarn2nix.mkYarnPackage {
  #   name = "brigade-worker";
  #   src = fixed-source;
  #   packageJson = "${fixed-source}/package.json";
  #   yarnLock = "${fixed-source}/yarn.lock";
  #   preBuild = ''
  #     yarn run build
  #   '';
  # };

 extension = pkgs.yarn2nix.mkYarnPackage {
    name = "brigade-extension";
    src = ./.;
    packageJson = ./package.json;
    yarnLock = ./yarn.lock;
    publishBinsFor = ["typescript"];
    postBuild = ''
      yarn run build
    '';
  };
}