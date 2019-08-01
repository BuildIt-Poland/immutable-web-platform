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

#### Reverse proxy
#### istio virtual service
- forwarding traffic with `virtualservice` to host works good, but if something is serving frontend then there is a problem - example `grafana` even when `GF_SERVER_ROOT_URL` forwarding does not work well

#### nginx-ingress
- require extra work to spin up services in different namespaces

# grafana behind proxy: https://github.com/grafana/grafana/issues/16613
https://github.com/istio/istio/issues/9247
https://github.com/grafana/grafana/issues/16613
knative has a bit outdated grafana - recent versions allow to https://github.com/grafana/grafana/pull/17048 

# kind an local-proxy
### kind and localrepo
- it is a bit slow to push docker images to kind, besides version greater than 0.2.1 does not allow to upload images build from `nix/docker on mac` since `crs` showing invalid `tgz header`
- with custom repo, upload is done by docker and recognize uploaded layers - it is faster
  # WHY: https://github.com/windmilleng/kind-local#why
  # + able to bump kind to 0.4.0

update: actually `kube-registry-proxy` allows to skip `path` (above) on `kind` and give possibility to point to whatever registry is out there

update 2: acutally above does not work with `knative` - required is to have url ending with `.local`, like `dev.local`

required changes to kind:
```
# apt-get update
# apt-get install vim
# vim /etc/containerd/config.toml
# systemctl restart containerd.service
# systemctl restart kubelet.service - unnecessary?

# preload is not necessary!!!
# crictl pull dev.local/dev/express-app:dev-build
```
droping kind to use minikube as is more mature and better for local development.

### kvm
* kvm is necessary to run nixos tests - there is no chance to run it on aws (except i3.metal) or locally on mac
* packet.net integration to run kvm https://github.com/input-output-hk/nixops/commit/786258da019577b20f76fc3b1d261488e13882ee