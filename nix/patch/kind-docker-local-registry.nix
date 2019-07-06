{ pkgs, writeShellScript, env-config }:
with pkgs.stdenv;
# TODO PASS port as a param
mkDerivation rec {
  name = "docker-registry-workaround";

  src = pkgs.fetchgit {
    url = "https://github.com/windmilleng/kind-local";
    rev = "ded8039f93512743fd3f3f7e0b8088adf7168483";
    sha256 = "0cn6wr8adyr4x8gm2w5w0zw7dvhxlybwn50kcjqaxdck0jvfacgd";
  };

  port = env-config.docker.local-registry.exposedPort;

  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp -ar $src/* $out/bin/

    sed \
      -e '2 i\DIR="$(dirname $(realpath $0))"' \
      -e 's/--name=\"kind\"/--name=\"$PROJECT_NAME\"/' \
      -e 's/cp\ config.toml/cp\ $DIR\/config.toml/' \
      -e 's/32001/${toString port}/' \
        $src/kind-registry.sh \
          | sed '$d' | sed '$d' | sed '$d' \
          > $out/bin/create-registry

    chmod +x $out/bin/create-registry
  '';
  nativeBuildInputs = [pkgs.kubectl];
}

