{ pkgs, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.3.1";
  name = "kubectl-tkn-${version}";
  src = fetchFromGitHub {
    owner = "tektoncd";
    repo = "cli";
    rev = "v${version}";
    sha256 = "0ni8g9klqgzhb01nw0ip9wbrmq4b8n9si9d2qjkbxbra16jgw1wq";
  };

  patches = [
  ];

  buildFlagsArray = ''
    -ldflags=
      -X=main.Version=${version}
  '';

  postInstall = ''
    ls -la $out/bin
    mv $out/bin/plugin $out/bin/kubectl-tkn
  '';

  subPackages = ["cmd/plugin"];
  goPackagePath = "github.com/tektoncd/cli";
  modSha256 = "0dyfhn5m937gr883yj771p608kdwhcrwi6dhp39fkagxmx80kj73";

  meta = with lib; {
    description = "The Tekton Pipelines cli project provides a CLI for interacting with Tekton!";
    homepage = https://github.com/tektoncd/cli;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}