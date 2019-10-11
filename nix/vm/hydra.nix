{ linux-pkgs, project-config, callPackage }:
let
  pkgs = linux-pkgs;
  express-app = callPackage ./package.nix {
    inherit pkgs;
   };
  fn-config = callPackage ./config.nix {};
in
pkgs.dockerTools.buildLayeredImage ({
  name = "hydra-nixos";

  maxLayers = 120;

  extraCommands = ''
    ${pkgs.nixos-generate}/bin/nixos-generate -f qcow -c ${pkgs.nixos-base} --system x86_64-linux
    echo "ooo"
  '';

  contents = [ 
    pkgs.nixos-base
    pkgs.coreutils
    pkgs.bash
  ];
# /disk/$FILE_NAME
  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = [""];
    # WorkingDir = "${express-app}";
    # ExposedPorts = {
    #   "${toString fn-config.port}/tcp" = {};
    # };
  };
} // { tag = "experimental"; })