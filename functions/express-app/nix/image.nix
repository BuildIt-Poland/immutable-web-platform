{ linux-pkgs, project-config, callPackage }:
let
  pkgs = linux-pkgs;
  express-app = callPackage ./package.nix {
    inherit pkgs;
   };
  fn-config = callPackage ./config.nix {};
  # base = pkgs.dockerTools.pullImage {
  #   imageName = "mhart/alpine-node";
  #   sha256 = "00nvrgp7s3c17ywhsanra1w3lrms0r8bfbd5zyg2jkq96bmbpiyf";
  #   imageDigest = "sha256:66ef5938c6a8a8793741ac7049395ea52c25ee825f49baabf7e347d9b9b97abe";
  #   os = "linux";
  #   arch = "amd64";
  # };
in
pkgs.dockerTools.buildLayeredImage ({
  name = project-config.docker.imageName fn-config.label;

  fromImage = base;
  maxLayers = 120;

  contents = [ 
    pkgs.coreutils
    pkgs.bash
    pkgs.nodejs-slim
    express-app # application
  ];

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions
  config = {
    Cmd = ["start-server"];
    WorkingDir = "${express-app}";
    ExposedPorts = {
      "${toString fn-config.port}/tcp" = {};
    };
  };
} // { tag = project-config.docker.imageTag fn-config.label; })