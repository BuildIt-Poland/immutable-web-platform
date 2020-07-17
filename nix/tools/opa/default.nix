{ lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "opa-${version}";
  version = "0.22.0";

  src = fetchFromGitHub {
    owner = "open-policy-agent";
    repo = "opa";
    rev = "v${version}";
    sha256 = "1cwvjaxzfx2msaa1cljkm6ca7d67yi1nba0yvqk0xmnkq69nwk92";
  };

  goDeps = ./deps.nix;
  goPackagePath = "github.com/open-policy-agent/opa";
  modSha256 = "0a00kcyagqczw0vhl8qs2xs1y8myw080y9kjs4qrcmj6kibdy55q";

  meta = with lib; {
    description = "The Open Policy Agent (OPA) is an open source, general-purpose policy engine that enables unified, context-aware policy enforcement across the entire stack.";
    homepage = https://github.com/open-policy-agent/opa;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}