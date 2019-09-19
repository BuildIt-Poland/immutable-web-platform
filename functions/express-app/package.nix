{ pkgs, gitignore }:
pkgs.yarn2nix.mkYarnPackage rec {
  src = ./.;
  name = "express-node";
  packageJson = ./package.json;
  yarnLock = ./yarn.lock;
}