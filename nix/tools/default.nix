{sources}:
self: super:
let
  nodePackages = ../../packages;
in
rec {
  # Terraform
  terraform-with-plugins = super.callPackage ./terraform {};

  # K8S
  open-policy-agent = super.callPackage ./opa {};
} 