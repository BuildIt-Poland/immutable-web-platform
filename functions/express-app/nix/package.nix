{ pkgs, env-config }:
let
  src = env-config.gitignore ../.;
in
pkgs.yarn2nix.mkYarnPackage rec {
  inherit src;

  name = "express-node";
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  # it would be cool to find some nicer solution
  preConfigure = ''
    rm -rf ./result
  '';
}