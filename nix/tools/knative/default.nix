{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "kn-${version}";
  version = "0.master.0";

  src = fetchFromGitHub {
    owner = "knative";
    repo = "client";
    rev = "34fcd89bcde084ecd2a1da8390f0ae097959b091";
    sha256 = "1c6a578m2n9d2kjvj3gj886wpaksagprsvlaw5cq5fzz7fpzncp2";
  };

  goPackagePath = "github.com/knative/client";
  modSha256 = "1vxqi0ja2phwy6sci79g833lf9kd9gm1a5r6nbsdgzsncijw9c3j";

  postInstall = ''
    cp $out/bin/kn $out/bin/kubectl-kn
  '';

  meta = with lib; {
    description = "Knative CLI";
    homepage = https://github.com/knative/client;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}