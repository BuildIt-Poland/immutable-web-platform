{ pkgs, gitignore }:
pkgs.yarn2nix.mkYarnPackage rec {
  src = gitignore ./.;
  name = "express-node";
  packageJson = ./package.json;
  yarnLock = ./yarn.lock;
}