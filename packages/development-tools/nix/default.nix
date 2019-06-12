{ pkgs, env-config }:
pkgs.yarn2nix.mkYarnPackage {
  name = "development-tools";
  src = env-config.gitignore ./..;
  packageJson = ../package.json;
  publishBinsFor = ["localtunnel"];
  yarnLock = ../yarn.lock;
  postBuild = ''
  '';
}