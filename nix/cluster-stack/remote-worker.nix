
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

  nix-docker = import (
    pkgs.fetchFromGitHub {
      owner = "LnL7";
      repo = "nix-docker";
      sha256 = "1ragp0fm6d4qzc067fbv90brgykm0v7fi78ggh1mkwdcnf6qy0gx";
      rev = "f750cee621610b0b5718afcf20f922c39a3a6da0";
  }) {};
in
pkgs.dockerTools.buildImage ({
  name = "remote-worker";
  tag = "latest";

  fromImageName = image;
  fromImageTag = "latest";

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