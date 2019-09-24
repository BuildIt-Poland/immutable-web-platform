{ pkgs, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "master";
  name = "kube-psp-advisor-${version}";
  src = fetchFromGitHub {
    owner = "sysdiglabs";
    repo = "kube-psp-advisor";
    rev = "${version}";
    sha256 = "15y7y6pbcblinn0xx2w6gizc6zixzpzwxrrk5qsh4nk0klfb205g";
  };

  patches = [
  ];

  buildFlagsArray = ''
    -ldflags=
      -X=main.Version=${version}
  '';

  subPackages = [
    "." 
  ];

  goPackagePath = "github.com/sysdiglabs/kube-psp-advisor";
  modSha256 = "1h2lbb08yj1rcsn9lvlwaw8ppn0lmjb6nnpyc4bwnlrac0ih2394";

  meta = with lib; {
    description = "Help building an adaptive and fine-grained pod security policy.";
    homepage = https://github.com/sysdiglabs/kube-psp-advisor;
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}