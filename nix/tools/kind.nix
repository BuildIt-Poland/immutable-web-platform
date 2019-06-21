{ pkgs, writeShellScript }:
with pkgs.stdenv;
# INFO before moving to 0.3.0 instead of tar.gz we need to have tar
# for now option is to, create local docker repository (not a big fan),
# or do a docker load < *.tar.gz, and then docker save sth:sth -o image.tar

# INFO 0.3.0 - from what they said in docs it should be faster - however I don't see that way
# when I'm exporting the same image timmings are the same, most likely realated to
# https://github.com/kubernetes-sigs/kind/pull/382 
# 
let
  version = "0.2.1";
  # version = "0.3.0";
  bin-name = "kind";
  url = {version, os}: 
    "https://github.com/kubernetes-sigs/kind/releases/download/${version}/kind-${os}-amd64";

  getSource = {version, os}: pkgs.fetchurl {
    url = url { inherit version os; };
    sha256 = "1yd61xn8wb3xk9ywxjaxhqahiamfzrdip9i9gr2rbqshgwi8s1zl";
    # sha256 = "13396vbwa0b3gx0kpl85jsgslbj5dadyfmf6h8n00cb4ffxzvsil"; # 0.3.0
  };
in
mkDerivation rec {
  inherit version name;

  src = 
    if isDarwin
      then getSource {inherit version; os = "darwin";}
      else getSource {inherit version; os = "linux";};

  buildInputs = [ ];
  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${bin-name}
    chmod +x $out/bin/${bin-name}
  '';
}

