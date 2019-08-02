source run-linux-worker.sh
nix-shell \
  --arg kubernetes '{update=true;}' \
  --arg docker '{upload=true;}' \
  --arg tests '{enable=true;}'

# nix-shell \
#   --arg kubernetes '{clean= false; update=true;}' \
#   --arg docker '{upload=false;}' \
#   --arg tests '{enable=false;}'