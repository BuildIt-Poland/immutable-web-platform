machine_ip=$(terraform output nixos_public_ip)
echo $machine_ip
ssh root@$machine_ip  -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no"