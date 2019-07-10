### Purpose
Yet another story about `kubernetes` and declarative approach to infrastructure ... in nutshell. 
... being more verbose ... fully automated `kubernetes` environment based on `FaaS` to be run on local environment, virtual machines or in cloud based leveraging `nixos` and `nixpkgs` ecosystem. This is an example architecture how things can be modeled in fully reproducible manner, be language agnostic and 
provide full testing ability of infrastructure as well as on application level following `gitops` way realized by `brigade.js` and `argo cd`.

### Inspiration part
* [kubernetes in nix](https://www.youtube.com/watch?v=XgZWbrBLP4I)
* [brigade js in action](https://www.youtube.com/watch?v=yhfc0FKdFc8&t=1s)
* [some why`s around nix](https://www.youtube.com/watch?v=YbUPdv03ciI)
* [knative](https://www.youtube.com/watch?v=69OfdJ5BIzs)
* [brigade & virtual-kubelet](https://cloudblogs.microsoft.com/opensource/2019/04/01/brigade-kubernetes-serverless-tutorial/)
* [argo cd](https://argoproj.github.io/argo-cd/)

### What is super hot!
* `helm charts` without `helm` and `tiller`
* scale to `0` with `knative & istio`, scale based on concurrency level
* fully declarative descriptor of environment to provision `local` env, `virtual machine` as well as `clouds` based on `nixpkgs` and `nixOS`
* pure `nix` solution - there is no any `yaml` file related to descriptor `docker`, `kubernetes` or `helm`
* `nix` in charge of building and pushing docker images to `docker repository`
* full composability of components and configs
* full determinism of results
* incremental builds! - if there were no change, artifact, docker or any other thing won't be builded
* diverged targeted builds - `darwin` and `linux` in the same time within nested closures - required for local docker provisioning
* distributed build cache and sharing intermediate states between builds - remote stores to speed up provisioning and `ci` results - work in progress
* `nixops` is provisioning based upon `declarative` nix file
* I can share all `nix` code across everything and don't worry about copying any `bash` scripts
* custom tool to manage remote state for deployments called `remote-state` (check `infra/shell.nix` for usage or it's [docs](/packages/remote-state/README.md))
* gitops
* monitoring tools
* local docker registry

### People are doing it already ...
* [step towards future configuration infrastructure management nix](https://container-solutions.com/step-towards-future-configuration-infrastructure-management-nix/)
* [how we use nix at iohk](https://iohk.io/blog/how-we-use-nix-at-iohk/)

#### Tools comparison
* [ansible vs nix](https://github.com/WeAreWizards/blog/blob/master/content/articles/ansible-and-nix.md)
* [docker vs nix](https://discourse.nixos.org/t/is-there-much-difference-between-using-nix-shell-and-docker-for-local-development/807)

#### Good to familiar with
* [`knative with knctl`](https://developer.ibm.com/blogs/knctl-a-simpler-way-to-work-with-knative/)
* [`docker-containers`](https://github.com/NixOS/nixpkgs/pull/55179)
* [`nixos container`](https://nixos.org/nixos/manual/#ch-containers)
* [`distributed builds`](https://nixos.wiki/wiki/Distributed_build)
* [`nix & docker`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix)

#### Some articles which were helpful down the road
* [`nix & concourse`](https://memo.barrucadu.co.uk/concourseci-nixos.html)
* [`nix & kubernetes`](https://rzetterberg.github.io/kubernetes-nixos.html)

### Docs
* [How brigade work](/docs/brigade.md)
* [How cache is handled](/docs/cache.md)
* [How to debug](/docs/debugging.md)
* [How to setup local development](/docs/development.md)
* [What kind of errors you can expect](/docs/errors.md)
* [What I have learnt down the road](/docs/lessons-learnt.md)
* [How secrets are handled](/docs/secrets.md)
* [What is the technology stack](/docs/stack.md)
* [Some tips and tricks](/docs/tips-and-tricks.md)
* [Where I'm and where I want to be](/docs/roadmap.md)
* [Some alternative approaches](/docs/alternatives.md)
* [Cluster monitoring](/docs/monitoring.md)
* [Some good reads](/docs/reads.md)
* [`nix-darwin` and `remote-builders`](/docs/linux-darwin-builds.md)

### How to start

#### You need to install these
* get [`docker`](https://www.docker.com/products/docker-desktop) - for [`kind`](https://kind.sigs.k8s.io/)
* get [`nix`](https://nixos.org/nix/download.html) - creating isolated local environment
* run `nix-shell` - if you encounter any issues check [docs](/docs/)

#### Monitoring
![grafana](https://bitbucket.org/repo/6zKBnz9/images/1943034243-Screenshot%202019-06-19%20at%2013.45.21.png)
![weavescope](https://bitbucket.org/repo/6zKBnz9/images/3906895708-Screenshot%202019-06-19%20at%2013.45.55.png)