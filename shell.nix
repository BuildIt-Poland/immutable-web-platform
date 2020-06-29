{ pkgs ? import <nixpkgs> {} }:
let
  # nixpkgs = import ./nix {};

  rootFolder = toString ./.;

  bootstrap = pkgs.writeScript "bootstrap" ''
    ${pkgs.cowsay}/bin/cowsay "Hey hey hey"
  '';
in
  pkgs.mkShell rec {
    NAME = "playground";
    nix_shell_name = "${name}#λ";
    MINIKUBE_CLUSTER = "${NAME}_cluster";
    HELM_HOME = (toString ./.) + "/.helm";
    ROOT_WORKSPACE = rootFolder;

    inherit bootstrap;

    buildInputs = with pkgs; [
      cowsay
      hello
      nodejs
      dhall
      dhall-json
      bazel
      buildozer
      bazel-watcher
      helmfile

      bashInteractive
    ];
}
