#!/bin/bash
# set -euo pipefail

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

echo "-- copying nix store --"
# NIX_SSHOPTS="${sshOpts[*]}" nix copy --to "ssh://$target_host" $build_hash
NIX_SSHOPTS="${sshOpts[*]}" nix-copy-closure --to $target_host $build_hash
echo "-- end --"

echo "-- switching configuration --"
test=$(ssh "${sshOpts[@]}" $target_host "sudo $build_hash/bin/switch-to-configuration switch" 2>&1)
should_rebot=$(echo $test | grep "init" | wc -c)

echo $should_rebot
echo "-- end --"

if [[ $should_rebot != 0 ]] ; then
  echo "-- rebooting instance --"
  ssh "${sshOpts[@]}" $target_host "reboot"
fi