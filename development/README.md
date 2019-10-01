### Dev workspaces

### Why
* rebuiliding nix-shell on watch with spawned multiple terminals (you will run watch run time and separate terminal with dir env will connect to this session) - in other word, there is no need to re-enter the shell all terminals which are spawned in the same dir will be invalidated

## Prerequisites
### Lorri
* read [here](https://github.com/target/lorri)
* follow instruction

## TODO - ASCI film

### To consider
* merge this with nix/targets/perspectives - actually I like it here - this is a dev workspace

### Running
* for the first time `nix-shell --option extra-binary-caches 's3://future-is-comming-dev-worker-binary-store?region=eu-west-2'  --option require-sigs false`

### Caveats
* https://github.com/target/lorri/issues/150