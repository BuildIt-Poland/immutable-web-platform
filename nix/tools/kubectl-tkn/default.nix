{ pkgs, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.3.1";
  name = "kubectl-tkn-${version}";
  src = fetchFromGitHub {
    owner = "tektoncd";
    repo = "cli";
    rev = "v${version}";
    sha256 = "1i5hlpgvg5yas09w6kqna8ldrfng0hy79h10dlvc3xrrdb85ds3q";
  };

  patches = [
  ];

  buildFlagsArray = ''
    -ldflags=
      -X=main.Version=${version}
  '';

  postInstall = ''
    cp $out/bin/tkn $out/bin/kubectl-tkn
  '';

  subPackages = ["cmd/tkn"];
  goPackagePath = "github.com/tektoncd/cli";
  modSha256 = "0yhmbfp3nnk92p07g2nmw31n0ima8yh1951llrw9wgjdlnr33klp";

  meta = with lib; {
    description = "The Tekton Pipelines cli project provides a CLI for interacting with Tekton!";
    homepage = https://github.com/tektoncd/cli;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}