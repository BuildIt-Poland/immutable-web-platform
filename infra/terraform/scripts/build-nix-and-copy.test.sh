build_hash=$(nix-build --attr system ../nixos/ec2-nixos.nix)
machine_ip=$(terraform output nixos_instance_ip)

nix copy --to "ssh://root@$machine_ip" ./result
ssh root@$machine_ip "sudo $build_hash/bin/switch-to-configuration switch"