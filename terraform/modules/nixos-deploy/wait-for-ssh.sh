#!/bin/bash
# set -euo pipefail

user=$1
host=$2

sshOpts=(
  -o "ControlMaster=auto"
  -o "ControlPersist=60"
  # Avoid issues with IP re-use. This disable TOFU security.
  -o "StrictHostKeyChecking=no"
  # -o "UserKnownHostsFile=/dev/null"
  -o "GlobalKnownHostsFile=/dev/null"
)

result=nook

while [[ $result != ok ]]; do
  result=$(ssh "${sshOpts[@]}" $user@$host echo ok 2>&1)
  echo Waiting for host to be available $result
  sleep 1
done