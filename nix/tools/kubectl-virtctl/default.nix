{ pkgs, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.21.0";
  name = "kubectl-virtctl-${version}";
  src = fetchFromGitHub {
    owner = "kubevirt";
    repo = "kubevirt";
    rev = "v${version}";
    sha256 = "0yx1zadf8rhzbbjnpy4j05n36amxd66zqshksdkydzyc8g7brqnv";
  };

  patches = [
  ];

  nativeBuildInputs = [
    pkgs.mercurial
  ];

  GOFLAGS="-mod=vendor";

  buildFlagsArray = ''
    -ldflags=
      -X=main.Version=${version}
  '';

  postInstall = ''
    cp $out/bin/virtctl $out/bin/kubectl-virt
    cp $out/bin/virtctl $out/bin/kubectl-virtctl
  '';

  subPackages = [
    "pkg/virtctl" 
    "cmd/virtctl"
  ];

  goPackagePath = "github.com/kubevirt/kubevirt";
  modSha256 = "044g4v9m6ski4qmxjhmz01l1zmd8ggmccay1harmvaa9bsc75wyk";

  meta = with lib; {
    description = "KubeVirt is a virtual machine management add-on for Kubernetes. The aim is to provide a common ground for virtualization solutions on top of Kubernetes.";
    homepage = https://github.com/kubevirt/kubevirt;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}