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