{ pkgs }:
pkgs.yarn2nix.mkYarnPackage {
  name = "development-tools";
  src = ./.;
  packageJson = ./package.json;
  publishBinsFor = ["localtunnel"];
  yarnLock = ./yarn.lock;
  postBuild = ''
  '';
}