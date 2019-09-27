{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "mkcert-${version}";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "FiloSottile";
    repo = "mkcert";
    rev = "v${version}";
    sha256 = "0xcmvzh5lq8vs3b0f1zw645fxdr8471v7prl1656q02v38f58ly7";
  };

  # subPackages = ["."];

  goPackagePath = "github.com/FiloSottile/mkcert";
  modSha256 = "0an12l15a82mks6gipczdpcf2vklk14wjjnk0ccl3kdjwiw7f4wd";

  meta = with lib; {
    description = "mkcert is a simple tool for making locally-trusted development certificates. It requires no configuration";
    homepage = https://github.com/FiloSottile/mkcert;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}