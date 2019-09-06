{ pkgs, gitignore }:
pkgs.yarn2nix.mkYarnPackage {
  name = "brigade-extension";
  src = gitignore ./..;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  postBuild = ''
    yarn run build
  '';
}