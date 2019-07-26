{ pkgs, gitignore }:
pkgs.yarn2nix.mkYarnPackage rec {
  src = gitignore ../.;
  name = "express-node";
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  # it would be cool to find some nicer solution
  preConfigure = ''
    rm -rf ./result
  '';
}