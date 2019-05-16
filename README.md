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

### Required
* `nix` - `nix`
* `nixops` - `nix-env -i nixops`
* `virtualbox` - for local development

### Infrastructure provisioning
#### Why
Test localy on `virtualbox`, deploy to `aws` or `azure` latter on.

#### Creating deployment
* `nixops create ./infra/ci/nixos.nix ./infra/ci/machine.nix -d concourse-ci`
* `nixops deploy -d concourse-ci`

#### Loggin into the `nixos` `virtualbox`
* `nixops ssh -d <deployment_name>`
* changing password (if you want to play in non headless mode) `passwd`

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
* [arion](https://github.com/hercules-ci/arion) - nix docker compose
* [nixops](https://nixos.org/nixops/) - provisioning tool

#### TODO
* docker - https://github.com/NixOS/nixpkgs/pull/55179/files
* gitignore - https://nixos.org/nixpkgs/manual/#sec-pkgs-nix-gitignore
* provision to `ec2`

#### Debugging
* `systemctl cat container@database.service`
* `systemctl status container@database.service`
* `systemctl status test-service`

#### When you are new - some user stories & articles
* https://iohk.io/blog/how-we-use-nix-at-iohk/

#### Some important docs - how to
* [`docker-containers`](https://github.com/NixOS/nixpkgs/pull/55179)

#### Some inspirations
* [`nix & concourse`](https://memo.barrucadu.co.uk/concourseci-nixos.html) - more less ok, but I don't like this `yaml` files, besides newest `concourse` is not working with docker compose as worker is dying ...
* [`nix & kubernetes`](https://rzetterberg.github.io/kubernetes-nixos.html)

#### Changing direction
* `arion` and `docker-compose` is ok, however having troubles to setup it locally and on `vm`, so I expect that with `ec2` will be the same story. As `nixos` handle kuberntes and I've got already kubernetes resources, there is no point to use `docker-compose` in any variation. If I will setup kubernetes on `ec2` then most likely I can skip `eks` - however not sure if it is super easy.

#### Some lessons during hacking
> copying to `target` machine can be done via `environment.etc.local-folder.source = ./local-folder;`
  (related [discussion](https://groups.google.com/forum/#!topic/nix-devel/0AS_sEH7n-M))
  however as we can create derivation which I believe is more nix way as it provides artifact rather than mutation.
> when attaching service via `systemd` and if it using `nix-build` as it is with `arion` then sourcing bashrc from `/etc/bashrc` is necessary - need to raise an issue agains that