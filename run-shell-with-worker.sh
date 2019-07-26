source run-linux-worker.sh
nix-shell --arg kubernetes '{update=true;}' --arg docker '{upload=true;}'