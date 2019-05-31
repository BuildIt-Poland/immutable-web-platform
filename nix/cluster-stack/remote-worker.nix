
{ linux-pkgs, env-config }:
let
  image = "lnl7/nix";
  port = 5000;

  pkgs = linux-pkgs;
  pynix = import (
    pkgs.fetchFromGitHub {
      owner = "adnelson";
      repo = "pynix";
      sha256 = "085l2krrgli4kf9vl8ywlyq36bbhahh8ysg22pqhk5z5vrmzvwp2";
      rev = "set_nix_state_path";
    }) {inherit pkgs;};
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
    pynix
  ];

  config = {
    Cmd = ["nix-serve -p ${toString port}"];
    ExposedPorts = {
      "${toString port}/tcp" = {};
    };
  };
})