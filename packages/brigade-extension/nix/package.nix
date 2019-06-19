{ pkgs, env-config }:
pkgs.yarn2nix.mkYarnPackage {
  name = "brigade-extension";
  src = env-config.gitignore ./..;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  postBuild = ''
    yarn run build
  '';
}