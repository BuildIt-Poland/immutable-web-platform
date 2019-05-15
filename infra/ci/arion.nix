{ stdenv, lib
, coreutils, docker_compose, jq
}:
let

  arion = stdenv.mkDerivation {
    name = "arion";
    src = builtins.fetchGit {
      url = https://github.com/hercules-ci/arion;
    };
    unpackPhase = "";
    buildPhase = "";
    installPhase = ''
      mkdir -p $out/bin $out/share/arion
      cp -a nix $out/share/arion/
      cp -a src/arion-image $out/share/arion/
      tar -czf $out/share/arion/arion-image/tarball.tar.gz -C src/arion-image/tarball .
      substitute src/arion $out/bin/arion \
        --subst-var-by path ${lib.makeBinPath [jq coreutils docker_compose]} \
        --subst-var-by nix_dir $out/share/arion/nix \
        ;
      chmod a+x $out/bin/arion
    '';
    inherit passthru;
  };

  passthru = {
    inherit eval build;
  };

  eval = import "${nix_dir}/eval-composition.nix";

  build = args@{...}:
    let composition = eval args;
    in composition.config.build.dockerComposeYaml;

  nix_dir = "${arion.outPath}/share/arion/nix";

in
  arion