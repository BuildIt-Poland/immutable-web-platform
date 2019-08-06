
{ linux-pkgs, project-config,writeScriptBin }:
let
  pkgs = linux-pkgs;

  worker = pkgs.dockerTools.pullImage {
    imageName = "lnl7/nix";
    imageDigest = "sha256:ce464ba56607781dea11bf7e1624b17391f7026d7335b84081627eb52f563c1e";
    sha256 = "14jan9181n0qjxfdmrc8ac2p02gkwybqkc9n0kgizaz2w16igsdq";
    os = "linux";
    arch = "amd64";
  };
in
# INFO: to avoid extending path like below, investigate
# pkgs.dockerTools.buildImageWithNixDb
pkgs.dockerTools.buildImage ({
  name = "${project-config.docker.namespace}/remote-worker";

  fromImage = worker;

  contents = [
    pkgs.bash
    pkgs.jq
    pkgs.sops
    pkgs.kubectl
    pkgs.curl
    pkgs.git
    pkgs.awscli
    # in case of github -> hub (https://github.com/github/hub)
  ];

  config.Cmd = [ "${pkgs.bashInteractive}/bin/bash" ];
  config.Env =
    [ "PATH=/root/.nix-profile/bin:/run/current-system/sw/bin:${pkgs.sops}/bin:${pkgs.kubectl}/bin:${pkgs.awscli}/bin"
      "MANPATH=/root/.nix-profile/share/man:/run/current-system/sw/share/man"
      "NIX_PAGER=cat"
      "NIX_PATH=nixpkgs=/root/.nix-defexpr/nixpkgs"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
} // { tag = project-config.docker.tag; })