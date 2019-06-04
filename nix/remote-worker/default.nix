{
  pkgs, 
  callPackage,
  kubenix
}:
with kubenix.lib;
let
  config = callPackage ./config.nix {
    inherit pkgs;
  };

  result = k8s.mkHashedList { 
    items = config.kubernetes.objects;
  };

  k8s-resources = toYAML result;
  docker-images = config.docker.export;

  docker-image = callPackage ./image.nix {};
in
rec {
  inherit docker-image;
}
