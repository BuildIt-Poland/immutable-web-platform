source run-linux-worker.sh
# nix-shell --arg kubernetes '{clean= true; update=true;}'
nix-shell --arg uploadDockerImages true --arg fresh true --arg updateResources true