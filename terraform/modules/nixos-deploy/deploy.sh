#!/bin/bash
# set -euo pipefail

build_hash=$1
host=$2
# user=$3
user=root

./wait-for-ssh.sh root $host
./copy-nix.sh $hash $host