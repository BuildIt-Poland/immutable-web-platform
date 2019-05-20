### Purpose
As I'm super passionate about `nix` and it's ecosystem, I'd like share this awesomeness on some common `ops` tasks in examples to increase `nix` adoption within `buildit`.

### Inspiration part
* [kubernetes in nix](https://www.youtube.com/watch?v=XgZWbrBLP4I)
* [brigade js in action](https://www.youtube.com/watch?v=yhfc0FKdFc8&t=1s)
* [some why`s around nix](https://www.youtube.com/watch?v=YbUPdv03ciI)

### Goal
* deploy `https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/` - I need to have something to work with `knative` as a project sounds good
* spin up `distributed build cache` - to make building and provisioning super fast
* spin up `brigade.js` to not using any `CI` solution - architecture should be event driven
* spin up `k8s cluster` on `ec2` not `eks` - just to try alternative solution which has less assumptions from vendor
* make infrastructure testable, ...[more](https://nixos.org/nixos/manual/index.html#sec-nixos-tests)

## How to
### Building images from derivation
* `nix-build nix -A functions.express-app.images --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`
* `docker load < result`
* and then `docker run -it <container_id> /bin/sh`

### Pushing `docker-image`
* `nix-build nix -A functions.express-app.pushDockerImages --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`

### Start
### Required
* [`nixpkgs`](https://nixos.org/nix/download.html)
* [`nixops`](https://nixos.org/nixops/manual/#chap-installation) - `nix-env -i nixops`
* [`docker`](https://www.docker.com/get-started) - for local development
* run `nix-env -if ./nix/external/direnv.nix` - more about [`direnv`](https://direnv.net/)
* run `nix-env -if nix/external/lorri`

### Infrastructure provisioning
#### Why
Test localy on `virtualbox`, deploy to `aws` or `azure` latter on.

#### Creating deployment
* `nixops create ./infra/ci/nixos.nix ./infra/ci/machine.nix -d concourse-ci`
* `nixops deploy -d concourse-ci`

#### Loggin into the `nixos` `virtualbox`
* `nixops ssh -d <deployment_name>`
* changing password (if you want to play in non headless mode) `passwd`

#### Starting local env
* `lorri shell`

### Building docker with nix on `mac`
* setup a `builder` - `source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)`
> This script going to download docker worker as well as setup some keys and export env var related to builder (`NIX_REMOTE_SYSTEMS`), however if you will go with new shell over and over again, you can re-run the script or, build with `--builders`, like so `nix-build <your-build.nix> --builders 'ssh://nix-docker-build-slave x86_64-linux'`

### Docker compose substitution
* `nix-env -iA arion -f https://github.com/hercules-ci/arion/tarball/master`

### Important
* when pushing to docker registry, provide your [credentials](https://github.com/containers/skopeo#private-registries-with-authentication) - on `os x` auth via `keychain` does not work - simple workaround is to delete `credStore` do the login and should be all good.

### Helpful - when you need someting
* https://nixos.org/nixos/options.html#

#### What is so super awesome
* `nixops` is provisioning based upon `declarative` nix file
* I can share all `nix` code across everything and don't worry about copying any `bash` scripts

### Issues so far
* https://github.com/NixOS/nixpkgs/issues/60313 - bumping nix channel and using `master` - works!

### Tools

#### Libraries
* [niv](https://github.com/nmattia/niv) - nix setup
* [kubenix](https://github.com/xtruder/kubenix/tree/kubenix-2.0) - k8s

#### Provisioning
* [nixops](https://nixos.org/nixops/)
* [helm](https://helm.sh/)

#### OS
* [nixos](https://nixos.org/nixos/about.html)

#### Local
* [kind](https://github.com/kubernetes-sigs/kind)
* [lorri](https://github.com/target/lorri)

#### TODO
* setup `nix-channel`
* setup `ci` - scratching my head ... `concourse-ci` or `hydra` -> `brigade.js` and remote workers!
* setup distributed cache - `s3`
* sharing state for `nixops`
* docker - https://github.com/NixOS/nixpkgs/pull/55179/files
* gitignore - https://nixos.org/nixpkgs/manual/#sec-pkgs-nix-gitignore
* provision to `ec2`
* [formatting](https://github.com/serokell/nixfmt)

#### Debugging - within `nixos`
* `systemctl cat container@database.service`
* `systemctl status container@database.service`
* `systemctl status test-service`
* just to have wrapping `systemctl status --no-pager --full`

#### When you are new - some user stories & articles
* https://iohk.io/blog/how-we-use-nix-at-iohk/

#### Some important docs - how to
* [`docker-containers`](https://github.com/NixOS/nixpkgs/pull/55179)
* [`nixos container`](https://nixos.org/nixos/manual/#ch-containers)
* [`distributed builds`](https://nixos.wiki/wiki/Distributed_build)

#### Some articles which were helpful down the road
* [`nix & concourse`](https://memo.barrucadu.co.uk/concourseci-nixos.html)
* [`nix & kubernetes`](https://rzetterberg.github.io/kubernetes-nixos.html)

#### Changing direction
* `arion` and `docker-compose` is ok, however having troubles to setup it locally and on `vm`, so I expect that with `ec2` will be the same story. As `nixos` handle kuberntes and I've got already kubernetes resources, there is no point to use `docker-compose` in any variation. If I will setup kubernetes on `ec2` then most likely I can skip `eks` - however not sure if it is super easy.

#### Some lessons during hacking
> copying to `target` machine can be done via `environment.etc.local-folder.source = ./local-folder;`
  (related [discussion](https://groups.google.com/forum/#!topic/nix-devel/0AS_sEH7n-M))
  however as we can create derivation which I believe is more nix way as it provides artifact rather than mutation.
> when attaching service via `systemd` and if it using `nix-build` as it is with `arion` then sourcing bashrc from `/etc/bashrc` is necessary - need to raise an issue agains that
> running `docker-container` within `container` - [no chance](https://github.com/NixOS/nixpkgs/issues/28659) - trying with `rkt` - getting loop ...
> when using containers - if container does not work, it tell us that this container has to be restarted (ping to check is enough) - checking how to do autorestart without `--force-reboot` flag