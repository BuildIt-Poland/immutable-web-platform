{ yarn2nix }:
yarn2nix.mkYarnPackage {
  name = "express-node-app";
  src = ../.;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
}