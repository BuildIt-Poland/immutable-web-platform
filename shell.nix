let
  pkgs = import ./nix {};

  rootFolder = toString ./.;

  config = pkgs.lib.traceVal 
    (pkgs.dhallToNix (builtins.readFile ./nix/config/shell_config.dhall));

  bootstrap = pkgs.writeScript "bootstrap" ''
    ${pkgs.cowsay}/bin/cowsay "Hey hey hey"
    echo ${config.greeting}
    echo ${builtins.toJSON config.AWS}
  '';
in
  pkgs.mkShell rec {
    NAME = "playground";
    NIX_SHELL_NAME = "${NAME}#λ";
    MINIKUBE_CLUSTER = "${NAME}_cluster";
    HELM_HOME = (toString ./.) + "/.helm";
    ROOT_WORKSPACE = rootFolder;

    inherit bootstrap;

    buildInputs = with pkgs; [
      cowsay
      hello
      # nodejs
      # niv

      dhall
      dhall-json
      # dhall-nix

      bazel
      buildozer
      bazel-watcher
      helmfile

      bashInteractive

      open-policy-agent
    ];
}
