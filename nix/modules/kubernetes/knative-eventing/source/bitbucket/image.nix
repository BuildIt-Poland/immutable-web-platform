# https://github.com/nachocano/bitbucket-source
{ linux-pkgs, callPackage, project-config, lib, writeScriptBin }:
let
  pkgs = linux-pkgs;
  make-package = import ./package.nix {
    pkgs = linux-pkgs;
  };
in
  sub-packages: 
  image-name:
  cmd:
    let
      package = make-package sub-packages;
    in
    pkgs.dockerTools.buildLayeredImage ({
      name = project-config.docker.imageName image-name;

      contents = [
        pkgs.bash
        pkgs.coreutils
        package
      ];

      config.Cmd = [ "${package}/bin/${cmd}" ];
      config.Env = [ ];
    } // { tag = project-config.docker.imageTag image-name; })