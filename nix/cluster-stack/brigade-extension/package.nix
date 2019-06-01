{ pkgs }:
pkgs.yarn2nix.mkYarnPackage {
  name = "brigade-extension";
  src = ./.;
  packageJson = ./package.json;
  yarnLock = ./yarn.lock;
  preBuild = ''
    echo "TODO transpile ts ..."
    ls $src
    ls $out
  '';
}