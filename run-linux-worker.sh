#!/usr/bin/env bash
echo "Setup linux worker"
source /dev/stdin <<< "$(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)";