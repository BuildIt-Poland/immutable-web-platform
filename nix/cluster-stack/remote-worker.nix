
{ linux-pkgs, env-config }:
let
  image = "lnl7/nix";
  port = 5000;
  pkgs = linux-pkgs;
  worker = pkgs.dockerTools.pullImage {
    imageName = image;
    imageDigest = "sha256:ce464ba56607781dea11bf7e1624b17391f7026d7335b84081627eb52f563c1e";
    sha256 = "14jan9181n0qjxfdmrc8ac2p02gkwybqkc9n0kgizaz2w16igsdq";
    os = "linux";
    arch = "amd64";
  };
in
pkgs.dockerTools.buildImage ({
  name = "remote-worker";
  tag = "latest";

  fromImage = worker;

  contents = [
    pkgs.bash
    pkgs.coreutils
    pkgs.nix-serve
  ];

  config = {
    Cmd = ["nix-serve -p ${toString port}"];
    ExposedPorts = {
      "${toString port}/tcp" = {};
    };
  };
})