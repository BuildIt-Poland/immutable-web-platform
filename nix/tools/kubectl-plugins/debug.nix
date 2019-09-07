{ pkgs, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.1.1";
  name = "kubectl-debug-${version}";
  src = fetchFromGitHub {
    owner = "aylei";
    repo = "kubectl-debug";
    rev = "v${version}";
    sha256 = "0ni8g9klqgzhb01nw0ip9wbrmq4b8n9si9d2qjkbxbra16jgw1wq";
  };

  patches = [
    ./debug-thrift.patch 
  ];

  buildFlagsArray = ''
    -ldflags=
      -X=main.Version=${version}
  '';

  postInstall = ''
    mv $out/bin/plugin $out/bin/kubectl-debug
  '';

  subPackages = ["cmd/plugin"];
  goPackagePath = "github.com/aylei/kubectl-debug";
  modSha256 = "0dyfhn5m937gr883yj771p608kdwhcrwi6dhp39fkagxmx80kj73";

  meta = with lib; {
    description = "kubectl-debug is an out-of-tree solution for troubleshooting running pods, which allows you to run a new container in running pods for debugging purpose.";
    homepage = https://github.com/aylei/kubectl-debug;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}