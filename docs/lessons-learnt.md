### Docker images and nix
* always put `config` to image, if you forgot about this, you will receive error from `kubernetes` related to `InspectionError`

#### Hard things
* multicompilation in one step - docker requires linux but I'm working on darwin - in two steps it is easy - got the solution! overriding `pkgs` in overlay did the job - this is absolutely magic
> All functions are deployed to docker image, so it is required to keep only logic related to function and kubernetes resources or any function which would be run in container in case of developing on `os x` - in short, there cannot be any scripts which is allowed to run in `nix-shell` (TODO rephrase it ...)

* local environment - if we spawnin local cluster, and we are creating images locally we need to push docker to cluster without a need to push to docker registry - newest `kind` handle `kind load image-archive`

* running integration test from `nix` - [issue](https://stackoverflow.com/questions/54251855/virtualbox-enable-nested-vtx-amd-v-greyed-out) is that ... on `intel` processors there is no way to enable `kvm` virtualization - no idea for now ...

* knative ... https://github.com/knative/docs/issues/1234 - it was hard since in case of local docker, there has to be some tricks applied to make a name of local docker image prefixed by `dev.io/<docker_image>`

* `kubenix` for `helm` module is doing `chart2json` so in chart `json` file cannot be specified - there is a extra helper for it `chart-from-git`

#### Some lessons during hacking
> copying to `target` machine can be done via `environment.etc.local-folder.source = ./local-folder;`
  (related [discussion](https://groups.google.com/forum/#!topic/nix-devel/0AS_sEH7n-M))
  however as we can create derivation which I believe is more nix way as it provides artifact rather than mutation.
> when attaching service via `systemd` and if it using `nix-build` as it is with `arion` then sourcing bashrc from `/etc/bashrc` is necessary - need to raise an issue agains that
> running `docker-container` within `container` - [no chance](https://github.com/NixOS/nixpkgs/issues/28659) - trying with `rkt` - getting loop ...
> when using containers - if container does not work, it tell us that this container has to be restarted (ping to check is enough) - checking how to do autorestart without `--force-reboot` flag