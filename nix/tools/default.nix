{sources}:
self: super:
let
  nodePackages = ../../packages;
in
rec {
  # Infra
  terraform-with-plugins = super.callPackage ./terraform {};

  # Application
  ## Auth
  open-policy-agent = super.callPackage ./opa {};
  swagger-codegen = super.callPackage ./swagger-codegen {};
} 