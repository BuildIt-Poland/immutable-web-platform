# TODO Align to functions convention - keep stuff in /nix folder related to image and package
{ linux-pkgs, env-config }:
let
  image = "brigadecore/brigade-worker";
  port = 5000;
  pkgs = linux-pkgs;
  # DOCS: to get imageDigest use `skopeo inspect docker://docker.io/brigadecore/brigade-worker`
  # THIS IS MAGIC!
  worker = pkgs.dockerTools.pullImage {
    imageName = image;
    imageDigest = "sha256:94c85a0f50bf687c1b5ac88ae6a78b28720664efb13a096546cd8cb759820527";
    sha256 = "1r4ngh98ir7q2a0rlhjjgpp4hpmmi9y94lgq7n27vrwnzkjlqlvc";
    os = "linux";
    arch = "amd64";
  };
  brigade = pkgs.callPackage ./brigade-extension/package.nix {};
in
# INFO: this image is required to embed custom scripts
pkgs.dockerTools.buildImage ({
  name = "dev.local/brigade-worker";
  tag = "latest";

  fromImage = worker;

  extraCommands = ''
    ${pkgs.yarn}/bin/yarn add xml-simple
    ${pkgs.yarn}/bin/yarn add file:${brigade.extension}/tarballs/${brigade.extension.name}.tgz
  '';
    # ${pkgs.yarn}/bin/yarn add file:${brigade.base}/tarballs/${brigade.base.name}.tgz

  config = {
    Cmd = [ 
      "yarn run test" 
    ];
    WorkingDir = "/home/src";
  };

  contents = [
    # pkgs.bash
    # pkgs.coreutils
    # pkgs.yarn
  ];
})