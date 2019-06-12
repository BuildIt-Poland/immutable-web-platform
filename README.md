### Purpose
As I'm super passionate about `nix` and it's ecosystem, I'd like share this awesomeness on some common `ops` tasks in examples to increase `nix` adoption within `buildit`.

### Inspiration part
* [kubernetes in nix](https://www.youtube.com/watch?v=XgZWbrBLP4I)
* [brigade js in action](https://www.youtube.com/watch?v=yhfc0FKdFc8&t=1s)
* [some why`s around nix](https://www.youtube.com/watch?v=YbUPdv03ciI)
* [knative](https://www.youtube.com/watch?v=69OfdJ5BIzs)
* [brigade & virtual-kubelet](https://cloudblogs.microsoft.com/opensource/2019/04/01/brigade-kubernetes-serverless-tutorial/)

### Some handy tools
* [exposing docker ports for existing containers](https://sosedoff.com/2018/04/25/expose-docker-ports.html)

### Goal
* deploy `https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/` - I need to have something to work with `knative` as a project sounds good
* spin up `distributed build cache` - to make building and provisioning super fast
* spin up `brigade.js` to not using any `CI` solution - architecture should be event driven
* spin up `k8s cluster` on `ec2` not `eks` - just to try alternative solution which has less assumptions from vendor
* make infrastructure testable, ...[more](https://nixos.org/nixos/manual/index.html#sec-nixos-tests)

### What is super hot!
* `helm charts` without `helm` and `tiller`
* scale to `0` with `knative & istio`
* lo
* fully declarative descriptor of environment to provision `local` env, `virtual machine` as well as `clouds` based on `nixpkgs` and `nixOS`
* pure `nix` solution - there is no any `yaml` file related to descriptor `docker`, `kubernetes` or `helm`
* `nix` in charge of building and pushing docker images to `docker repository`
* full composability of components and configs
* full determinism of results
* incremental builds! - if there were no change, artifact, docker or any other thing won't be builded
* diverged targeted builds - `darwin` and `linux` in the same time within nested closures - required for local docker provisioning
* custom tool to manage remote state for deployments called `remote-state` (check `infra/shell.nix` for usage)

#### Work in progress
* `gitops` via `brigade.js`
* distrbuted build cache and sharing intermediate states between builds - remote stores to speed up provisioning and `ci` results - work in progress
* ability to define test for infrastructure and cluster, [more here](https://nixos.org/~eelco/talks/issre-nov-2010.pdf)

### People are doing it already ...
* [step towards future configuration infrastructure management nix](https://container-solutions.com/step-towards-future-configuration-infrastructure-management-nix/)
* [how we use nix at iohk](https://iohk.io/blog/how-we-use-nix-at-iohk/)

#### Tools comparison
* [ansible vs nix](https://github.com/WeAreWizards/blog/blob/master/content/articles/ansible-and-nix.md)
* [docker vs nix](https://discourse.nixos.org/t/is-there-much-difference-between-using-nix-shell-and-docker-for-local-development/807)

## How to
### Running clean cluster
* `nix-shell --arg fresh true`

> These ... below are already integrated with nix-shell! in case of local environment cluster is provisioned automatically, you can rerun using `push-docker-images-to-local-cluster`

### Building images from derivation
* `nix-build nix -A functions.express-app.images --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`
* `docker load < result`
* and then `docker run -it <container_id> /bin/sh`

### Pushing `docker-image`
* `nix-build nix -A functions.express-app.pushDockerImages --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`

### Setup brigade
* generate `ssh-key` only for your `bitbucket` hook. named your key as `bitbucket-webook` and place in `~/.ssh/` folder - (no worries, it can be changed in `nix/default.nix`)

### Start
### Required
* [`nixpkgs`](https://nixos.org/nix/download.html)
* [`nixops`](https://nixos.org/nixops/manual/#chap-installation) - `nix-env -i nixops`
* [`docker`](https://www.docker.com/get-started) - for local development

#### When developing
* if you are on `os x` enable `remote-worker`, more in [Building docker with nix on `mac`](#Building-docker-with-nix-on-mac)
* run `nix-shell`
#### or ... for pleasant development with watch
* run `nix-env -if ./nix/external/direnv.nix` - more about [`direnv`](https://direnv.net/)
* run `nix-env -if nix/external/lorri`

### Infrastructure provisioning
#### Why
Test localy on `virtualbox`, deploy to `aws` or `azure` latter on.

#### Creating deployment
* `cd infra`
* check `Makefile`

#### Running integration tests
* `nix-build release.nix -A integrationTest` - only on `nixos`, however not worries, already got that, you can run it from infra/Makefile

#### Loggin into the `nixos` `virtualbox`
* `nixops ssh -d <deployment_name>`
* changing password (if you want to play in non headless mode) `passwd`

#### Starting local env
* you can start `nix-shell`

or super fancy `lorri` with watch capability (check required section)
* `lorri shell` ()

### Building docker with nix on `mac`
* setup a `builder` - by running command within your shell (before you run nix-shell) `source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)`
> This script going to download docker worker as well as setup some keys and export env var related to builder (`NIX_REMOTE_SYSTEMS`), however if you will go with new shell over and over again, you can re-run the script or, build with `--builders`, like so `nix-build <your-build.nix> --builders 'ssh://nix-docker-build-slave x86_64-linux'`

### Setup local brigade
* run `create-localtunnel-for-brigade`
* after that you will get tunel, create webhook `https://tricky-grasshopper-9.localtunnel.me/events/bitbucket/`
* if you want to have auto-brigade configuration you have to pass `brigadeSharedSecret`, like so
`nix-shell --argstr brigadeSharedSecret "<bitbucket.webhooks.request.X-Hook-UUID>"`

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

#### Tips and Tricks
* [kubeclt wait](https://hackernoon.com/kubectl-tip-of-the-day-wait-like-a-boss-40a818c423ac)

#### When you are new - some user stories & articles


#### Some important docs - how to
* [`knative with knctl`](https://developer.ibm.com/blogs/knctl-a-simpler-way-to-work-with-knative/)
* [`docker-containers`](https://github.com/NixOS/nixpkgs/pull/55179)
* [`nixos container`](https://nixos.org/nixos/manual/#ch-containers)
* [`distributed builds`](https://nixos.wiki/wiki/Distributed_build)
* [`nix & docker`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix)

#### Some articles which were helpful down the road
* [`nix & concourse`](https://memo.barrucadu.co.uk/concourseci-nixos.html)
* [`nix & kubernetes`](https://rzetterberg.github.io/kubernetes-nixos.html)

#### Changing direction
* `arion` and `docker-compose` is ok, however having troubles to setup it locally and on `vm`, so I expect that with `ec2` will be the same story. As `nixos` handle kuberntes and I've got already kubernetes resources, there is no point to use `docker-compose` in any variation. If I will setup kubernetes on `ec2` then most likely I can skip `eks` - however not sure if it is super easy.
