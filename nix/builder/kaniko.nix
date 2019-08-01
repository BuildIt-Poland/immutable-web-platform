{pkgs}:
let
  safe-name = builtins.replaceStrings ["\/" "."] ["_" "_"];
in
{dockerfile, src, imageName}:
  # INFO require adding /nix to shared path in docker
  pkgs.stdenv.mkDerivation {
    inherit src;
    name = safe-name imageName;
    phases = ["installPhase"];
    buildInputs = [pkgs.docker];
    installPhase = ''
      cp -R $src/** .
      cp ${dockerfile} Dockerfile

      ${pkgs.docker}/bin/docker run \
        -v $(pwd):/usr \
        gcr.io/kaniko-project/executor:latest \
        --dockerfile=Dockerfile \
        --destination "${imageName}" \
        --context=/usr \
        --no-push \
        --tarPath=/usr/docker.test.tar 

      cat docker.test.tar > $out
    '';
  }