{ pkgs, gitignore }:
pkgs.yarn2nix.mkYarnPackage {
  name = "development-tools";
  src = gitignore ./..;
  packageJson = ../package.json;
  publishBinsFor = ["localtunnel"];
  yarnLock = ../yarn.lock;
  postBuild = ''
  '';
}