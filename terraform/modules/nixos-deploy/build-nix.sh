#!/bin/bash
set -euo pipefail

values=$1

nixos_configuration=$values
build_hash=$(nix-build --attr system $nixos_configuration)

cat <<JSON
{
  "hash": "$build_hash",
  "nixos_configuration": "$nixos_configuration"
}
JSON