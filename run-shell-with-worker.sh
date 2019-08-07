source run-linux-worker.sh
nix-shell \
  --arg kubernetes '{update=true;}' \
  --arg docker '{upload=true;}' \
  --arg tests '{enable=true;}' \
  --option binary-caches 's3://future-is-comming-worker-binary-store?region=eu-west-2'

# nix-shell \
#   --arg kubernetes '{clean= false; update=true;}' \
#   --arg docker '{upload=false;}' \
#   --arg tests '{enable=false;}'