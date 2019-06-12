{ pkgs }:
pkgs.yarn2nix.mkYarnWorkspace {
  name = "remote-state";
  src = ./..;
  packageJson = ../package.json;
  yarnLock = ../yarn.lock;
  packageOverrides = {
    remote-state-cli = {
      # publishBinsFor = ["remote-state-cli"];
      postBuild = ''
        yarn run build
      '';
    };
    remote-state-config = {
      postBuild = ''
        yarn run build
      '';
    };
    remote-state-aws-infra = {
      publishBinsFor = ["remote-state-aws-infra" "aws-cdk"];
      postBuild = ''
        yarn run build
      '';
    };
  };
}