#!/usr/bin/env bash
echo "Setup linux worker"
source /dev/stdin <<< "$(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)";

### with store
# docker run --name nix-docker-build-slave -d -p 3022:22 -p 5000:5000 lnl7/nix:ssh
# RUN nix-env -i nix-serve
# CMD nix-serve

# BUILD
# docker build -f functions/express-app/Dockerfile . --network=host