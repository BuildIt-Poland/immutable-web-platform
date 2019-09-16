source run-linux-worker.sh
nix-shell \
  --arg kubernetes '{update=true;}' \
  --arg docker '{upload=true;}' \
  --arg tests '{enable=true;}' \
  --arg opa '{validation=true;}' \
  --option binary-caches 's3://future-is-comming-worker-binary-store?region=eu-west-2'

# nix-shell \
#   --arg kubernetes '{clean= false; update=true;}' \
#   --arg docker '{upload=false;}' \
#   --arg tests '{enable=false;}'

# EKS
# nix-shell --arg kubernetes '{target="eks"; save=true; clean= false; update=true; patches=true;}' --arg docker '{upload=false;}' --arg tests '{enable=false;}'