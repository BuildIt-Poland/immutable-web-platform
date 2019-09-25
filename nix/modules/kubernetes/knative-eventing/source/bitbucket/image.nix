# https://github.com/nachocano/bitbucket-source
{ linux-pkgs, callPackage, project-config, lib, writeScriptBin }:
let
  pkgs = linux-pkgs;
  make-package = import ./package.nix {
    pkgs = linux-pkgs;
  };
in
  package-name: 
  image-name:
    let
      package = make-package package-name;
      cmd = lib.last (lib.splitString "/" package);
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