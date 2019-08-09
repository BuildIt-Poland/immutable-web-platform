#!/bin/bash

build_hash=$1
machine_ip=$2
user=root

buildArgs=(
  --option extra-binary-caches https://cache.nixos.org/
)

sshOpts=(
  -o "ControlMaster=auto"
  -o "ControlPersist=60"
  # Avoid issues with IP re-use. This disable TOFU security.
  -o "StrictHostKeyChecking=no"
  -o "UserKnownHostsFile=/dev/null"
  -o "GlobalKnownHostsFile=/dev/null"
)

target_host=$user@$machine_ip

# NIX_SSHOPTS="${sshOpts[*]}" nix copy --to "ssh://$target_host" $build_hash
NIX_SSHOPTS="${sshOpts[*]}" nix-copy-closure --to $target_host $build_hash
ssh "${sshOpts[@]}" $target_host "sudo $build_hash/bin/switch-to-configuration switch"