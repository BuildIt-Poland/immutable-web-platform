{ pkgs, lib, buildGoPackage, fetchFromGitHub }:
with pkgs.stdenv;
let
  version = "1.2.0";
  bin-name = "argocd";
  make-url = os: "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-${os}-amd64";
  bin-details = if isDarwin 
    then {
      url = make-url "darwin";
      sha256 = "0x3wjai7mihbixsminghk0vc8y0ghif9bd8ga81qjkhswsq86i78"; # sha for linux will be different
    }
    else {
      url = make-url "linux";
      sha256 = "009625d9ah6p0kih276ncmqwkak4b1cgap9zfmdk5dbw26srcbps"; # sha for linux will be different
    };
in
mkDerivation rec {
  inherit version;

  name = "argocd";

  src = pkgs.fetchurl bin-details;

  buildInputs = [ ];
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${bin-name}
    chmod +x $out/bin/${bin-name}
  '';
}

# THIS does not work AS: 
# they are building it via docker - missing vendor folder

# buildGoPackage rec {
#   name = "argocd-${version}";
#   version = "1.2.0";
#   rev = "v${version}";

#   src = fetchFromGitHub {
#     inherit rev;
#     owner = "argoproj";
#     repo = "argo-cd";
#     sha256 = "06cxpsdbmynpprxnaq8ciplan2ha61vmlqzp5q2bmd9r0palh7p2";
#   };

#   buildInputs = [ pkgs.go-bindata pkgs.git pkgs.which ];

#   # They are using packer here - somehow I need to copy vendor
#   # buildPhase = ''
#   #   cd go/src/${goPackagePath}
#   #   patchShebangs .
#   #   make cli
#   # '';

#   # installPhase = ''
#   #   ls -la 
#   # '';

#   goDeps = ./deps-1-2-0.nix;
#   subPackages = [ "cmd/argocd" ];
#   # output = ["bin"];
#   goPackagePath = "github.com/argoproj/argo-cd";
#   outputs = [ "bin" "out" "man" ];
#   modSha256 = "06cxpsdbmynpprxnaq8ciplan2ha61vmlqzp5q2bmd9r0palh7p3";

#   meta = with lib; {
#     description = "Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.";
#     homepage = https://github.com/argoproj/argo-cd;
#     license = licenses.asl20;
#     platforms = platforms.unix;
#   };
# }