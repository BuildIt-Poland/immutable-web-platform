
{ stdenv, fetchFromGitHub, buildGoModule }:
buildGoModule rec {
  name = "terraform-provider-nix-${version}";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "andrewchambers";
    repo = "terraform-provider-nix";
    rev = "v${version}";
    sha256 = "17nmnna56xlscajx94hqilcp0jjvcbg7l8awqgkl46m9sfrj3w2g";
  };

  modSha256 = "1341fyxq900253l6j2rcazifsc4x8ncmz4smi5pwk38kbja65xli";

  subPackages = [ "." ];

  # Terraform allow checking the provider versions, but this breaks
  # if the versions are not provided via file paths.
  postInstall = "mv $out/bin/terraform-provider-nix{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for nix";
    homepage = "https://github.com/andrewchambers/terraform-provider-nix";
  };
}