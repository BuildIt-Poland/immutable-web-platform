{ pkgs, gitignore }:
pkgs.yarn2nix.mkYarnPackage {
  name = "brigade-extension";
  src = ./.;
  packageJson = ./package.json;
  yarnLock = ./yarn.lock;
  postBuild = ''
    yarn run build
  '';
}