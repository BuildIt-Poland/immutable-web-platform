{ pkgs }:
pkgs.yarn2nix.mkYarnPackage {
  name = "remote-state";
  src = ./..;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  publishBinsFor = ["aws-cdk" "remote-state"];
  postBuild = ''
    yarn run build
  '';
}