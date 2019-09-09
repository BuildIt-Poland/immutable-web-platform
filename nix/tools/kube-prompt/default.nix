{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "kube-prompt-${version}";
  version = "1.0.7";

  src = fetchFromGitHub {
    owner = "c-bata";
    repo = "kube-prompt";
    rev = "v${version}";
    sha256 = "000kcd8jl5zq66b09zpmk4rs08kx4xzmcnqx2kszzdq46h11pgqx";
  };

  goPackagePath = "github.com/c-bata/kube-prompt";
  modSha256 = "03pg49vhj5l1phzqkvziz8bkd0n55l7wki9bpf0bj5rniddyrfi7";

  meta = with lib; {
    description = "An interactive kubernetes client featuring auto-complete using go-prompt.";
    homepage = https://github.com/c-bata/kube-prompt;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}