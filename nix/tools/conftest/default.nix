# https://github.com/instrumenta/conftest/blob/master/go.mod#L51
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  name = "conftest-${version}";
  version = "9ef20efb81ea4607d47577077f5eef3382501f7c"; # above 0.12.0 - reason: patch related to thrive is already in master

  src = fetchFromGitHub {
    owner = "instrumenta";
    repo = "conftest";
    rev = "${version}";
    sha256 = "0q7fbyi83x7xr6q6cyrm1dm7mj6d000p2d2jhjmx3qkas6n3j9vw";
  };

  goPackagePath = "github.com/instrumenta/conftest";
  modSha256 = "04sz3m2lzji4m7c8x47ilvldni351x7rjl7dphscwawa23v5m920";
  subPackages = ["cmd"];

  postInstall = ''
    mv $out/bin/cmd $out/bin/conftest
  '';

  meta = with lib; {
    description = "conftest is a utility to help you write tests against structured configuration data. For instance you could write tests for your Kubernetes configurations, or Tekton pipeline definitions, Terraform code, Serverless configs or any other structured data.";
    homepage = https://github.com/instrumenta/conftest; 
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}