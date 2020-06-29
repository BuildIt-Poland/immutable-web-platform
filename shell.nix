{ pkgs ? import <nixpkgs> {} }:
let
  # nixpkgs = import ./nix {};

  rootFolder = toString ./.;

  bootstrap = pkgs.writeScript "bootstrap" ''
    ${pkgs.cowsay}/bin/cowsay "Hey hey hey"
  '';
in
pkgs.mkShell {
  NIX_SHELL_NAME = "#buildit > EISL";
  MINIKUBE_CLUSTER = "polyglot_platform_cluster";
  HELM_HOME = (toString ./.) + "/.helm";
  ROOT_WORKSPACE = rootFolder;
  
  inherit bootstrap;

  buildNativeInputs = [

  ];

  buildInputs = with pkgs; [
    cowsay
    hello
    nodejs
    dhall
    dhall-json
    bazel
    buildozer
    bazel-watcher

    bashInteractive
  ];
}
