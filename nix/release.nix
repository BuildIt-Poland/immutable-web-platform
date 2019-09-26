# TODO make it more like this https://github.com/NixOS/patchelf/blob/master/release.nix
# inputs -> check nix/targets/defaults.nix
{ src ? ./., supportedSystems ? ["x86_64-linux"], inputs ? {}, ... }: 
let 
  pkgs = (import src { 
    inputs = (pkgs.lib.recursiveUpdate {
      environment = {
        type = "dev"; 
        perspective = "hydra";
      };
    } inputs); }).pkgs;

  docker-images = 
    builtins.mapAttrs 
      (_: builtins.getAttr "image") 
      pkgs.project-config.modules.docker;

  tools = 
    with pkgs.lib;
    with builtins;
    let
      folders = 
        (attrNames 
          (filterAttrs (n: v: v == "directory")
            (readDir ./tools)));
    in
      foldl 
        (x: y: (recursiveUpdate x {"${y}" = (getAttr y pkgs);}))
        {}
        folders;

  binaries = pkgs.lib.mapAttrs (n: v:
    (pkgs.lib.genAttrs supportedSystems (system:
      let
        pkgs = (import src { 
          inherit system;

          inputs = {
            environment = {
              type = "dev"; 
              perspective = "release";
            }; 
          }; 
        }).pkgs;
      in rec {
        build = (builtins.getAttr n pkgs);
        tarball = pkgs.releaseTools.binaryTarball {
          name = "${n}-tarball";
          src = build;
          doCheck = false;
          showBuildStats = false;

          # INFO: workaround
          # not sure why test is failing
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/release/binary-tarball.nix#L74
          releaseName="${v.name}-tarball";

          installPhase = ''
            ${pkgs.coreutils}/bin/install --target-directory "$TMPDIR/inst/bin" -D ${v}/bin/${n}
          '';
        };
      }
    ))
  ) tools;
  
  charts = 
    pkgs.lib.filterAttrs 
      (n: v: !(pkgs.lib.isFunction v)) 
      pkgs.k8s-resources;

  channel = pkgs.releaseTools.channel {
    name = "pkgs";
    src = ../.;
    constituents = [ ];
  };

  nixos = {
    hydra = (import ./nixos/hydra.nix { preload = true; }).system;
  };

# TODO temp workaround
in (
     { inherit binaries; }
  // { inherit charts; }
  // { inherit channel; }
  // { inherit docker-images; }
  // { inherit nixos; }
  // { tests.smoke = pkgs.callPackage ./test.nix {}; }
  # // { images = {
  #   hydra = (pkgs.stdenv.mkDerivation {
  #     name = "hydra-iso";
  #     nativeBuildInputs = [pkgs.nixos-generator];
  #     phases = ["buildPhase"];
  #     buildPhase = ''
  #       nixos-generate -f qcow -c ${./nixos/hydra.nix}
  #     '';
  #   });
  # }; }
)