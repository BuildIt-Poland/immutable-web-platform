### Purpose
As I'm super passionate about `nix` I would like share this awesomeness on some common `ops` tasks to everyone and adopt this everywhere!

### Goal
* deploy `https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/`

### Building images from derivation
* `nix-build nix -A functions.express-app.images --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`
* `docker load < result`
* and then `docker run -it <container_id> /bin/sh`

### Pushing `docker-image`
* `nix-build nix -A functions.express-app.pushDockerImages --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`

### Insipration
* https://www.tweag.io/posts/2019-03-07-configuring-and-testing-kubernetes-clusters.html
* https://memo.barrucadu.co.uk/concourseci-nixos.html

### Building docker with nix on `mac`
* setup a `builder` - `source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)`
> This script going to download docker worker as well as setup some keys and export env var related to builder (`NIX_REMOTE_SYSTEMS`), however if you will go with new shell over and over again, you can re-run the script or, build with `--builders`, like so `nix-build <your-build.nix> --builders 'ssh://nix-docker-build-slave x86_64-linux'`

### Important
* when pushing to docker registry, provide your [credentials](https://github.com/containers/skopeo#private-registries-with-authentication) - on `os x` auth via `keychain` does not work - simple workaround is to delete `credStore` do the login and should be all good.

### TODO
* setup `nix-channel`
* setup `ci` - scratching my head ... `concourse-ci` or `hydra`
* setup distributed cache - `s3`
* setup `nixops`

### Issues so far
* https://github.com/NixOS/nixpkgs/issues/60313 - bumping nix channel and using `master` - works!

### Development tools / Libraries
* [niv](https://github.com/nmattia/niv) - nix setup
* [kubenix](https://github.com/xtruder/kubenix/tree/kubenix-2.0) - k8s