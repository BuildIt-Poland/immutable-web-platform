## TODO

## priorities
* improve docs
* provide hooks for `nixops` infra updates
* apply scripts from local shell to `nixos` cluster
* running cluster in `brigade` worker to test release - `dind`

### `gitops` via `brigade.js`
* make brigade responsible for a `k8s` resources update with `git commit`, `infra` updates with `nixops`

### optimalization
* optimize docker images

### more investigation needed
* ability to define test for infrastructure and cluster, [more here](https://nixos.org/~eelco/talks/issre-nov-2010.pdf)

### nice to have
* setup `nix-channel`
* gitignore - https://nixos.org/nixpkgs/manual/#sec-pkgs-nix-gitignore
* [formatting](https://github.com/serokell/nixfmt)