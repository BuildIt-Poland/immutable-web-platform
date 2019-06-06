{ pkgs }:
pkgs.yarn2nix.mkYarnPackage {
  name = "brigade-extension";
  src = ./..;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  # publishBinsFor = ["typescript"];
  postBuild = ''
    yarn run build
  '';
}