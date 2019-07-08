{ linux-pkgs, env-config, callPackage, writeScriptBin }:
let
  pkgs = linux-pkgs;

  package = callPackage ./package.nix {};

  # DOCS: to get imageDigest use `skopeo inspect docker://docker.io/brigadecore/brigade-worker`
  base-docker = pkgs.dockerTools.pullImage {
    imageName = "brigadecore/brigade-worker";
    imageDigest = "sha256:94c85a0f50bf687c1b5ac88ae6a78b28720664efb13a096546cd8cb759820527";
    sha256 = "1r4ngh98ir7q2a0rlhjjgpp4hpmmi9y94lgq7n27vrwnzkjlqlvc";
    os = "linux";
    arch = "amd64";
  };
in
# INFO: this image is required to embed custom scripts
pkgs.dockerTools.buildImage ({
  name = "${env-config.docker.namespace}/brigade-worker";

  fromImage = base-docker;

  extraCommands = ''
    ${pkgs.yarn}/bin/yarn add \
      file:${package}/tarballs/${package.name}.tgz
  '';

  config = {
    Cmd = [ 
      "yarn run test" 
    ];
    Env = [ 
      "GIT_SSH=${gitssh}"
      "GIT_ASKPASS=${askpass}"
    ];
    WorkingDir = "/home/src";
  };

  contents = [];
} // env-config.docker.tag)