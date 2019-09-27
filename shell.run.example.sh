nix-shell \
  --arg kubernetes '{update=true;}' \
  --arg docker '{upload=true;}' \
  --arg tests '{enable=true;}' \
  --arg opa '{validation=true;}' \
  --option extra-binary-caches 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2'
