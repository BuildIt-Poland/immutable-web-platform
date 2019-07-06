### kind and localrepo
- it is a bit slow to push docker images to kind, besides version greater than 0.2.1 does not allow to upload images build from `nix/docker on mac` since `crs` showing invalid `tgz header`
- with custom repo, upload is done by docker and recognize uploaded layers - it is faster
  # WHY: https://github.com/windmilleng/kind-local#why
  # + able to bump kind to 0.4.0