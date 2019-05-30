
{ linux-pkgs, env-config }:
let
  image = "lnl7/nix";
  port = 5000;
  pkgs = linux-pkgs;
in
pkgs.dockerTools.buildImage ({
  name = "remote-worker";
  tag = "latest";

  fromImageName = image;
  fromImageTag = "latest";

  contents = [
    pkgs.bash
    pkgs.coreutils
    pkgs.hello
    pkgs.nix-serve
  ];

  config = {
    Cmd = ["nix-serve -p ${toString port}"];
    ExposedPorts = {
      "${toString port}/tcp" = {};
    };
  };
})