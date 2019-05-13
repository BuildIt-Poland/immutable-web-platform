### Purpose
* minimal setup of `nix` with building docker images and deploying stuff to `kubernetes`.

### Building docker with nix on `mac`
* setup a `builder` - `source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)`
> This script going to download docker worker as well as setup some keys and export env var related to builder (`NIX_REMOTE_SYSTEMS`), however if you will go with new shell over and over again, you can re-run the script or, build with `--builders`, like so `nix-build <your-build.nix> --builders 'ssh://nix-docker-build-slave x86_64-linux'`