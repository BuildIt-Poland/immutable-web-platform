
{ stdenv, fetchFromGitHub, buildGoModule }:
buildGoModule rec {
  name = "terraform-provider-nix-${version}";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "circuithub";
    repo = "terraform-provider-nix";
    rev = "f50411f38b5fca59c84df1c8a23edb0b53d14349";
    sha256 = "0hj2fawm78jx0nl3inmzsdl5dyi34clmbm92jcf404f0yhpwwfp6";
  };

  modSha256 = "1wnzyfsc470mnv8n2ymr4vs2x7x2macssyfzify5gk4vr9jjnc3v";

  subPackages = [ "." ];

  # Terraform allow checking the provider versions, but this breaks
  # if the versions are not provided via file paths.
  postInstall = "mv $out/bin/terraform-provider-nix{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for nix";
    homepage = "https://github.com/andrewchambers/terraform-provider-nix";
  };
}