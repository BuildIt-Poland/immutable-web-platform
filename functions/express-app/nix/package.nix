{ pkgs, env-config }:
pkgs.yarn2nix.mkYarnPackage {
  name = "express-node-app";
  src = env-config.gitignore ./..;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
}