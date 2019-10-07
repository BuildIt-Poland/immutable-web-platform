
# values=$1

# buildArgs=(
#   --option extra-binary-caches https://cache.nixos.org/ 
#   --option trusted-binary-caches 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2'
# )

nixos_configuration=$values
build_hash=$(nix-build --attr system $nixos_configuration ${buildArgs[*]})
nix-build \
  ./hydra.nix \
  --option binary-caches 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2 https://cache.nixos.org/' \
  --option require-sigs false \
  --attr system