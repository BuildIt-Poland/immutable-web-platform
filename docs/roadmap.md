## TODO
* populate docker registry or nixos docker repository
* make diffing of resources possible
* align ec2 deployment to `machine.json` descriptor
* create repository for infra code
* run example tests agains artifact in brigade
* setup brigade (serviceaccount) to be able to operate on kubernetes cluster (partially done - custom binding is there)
* forward `kubenix` results to brigade workers
* watch github hooks when approving the pull request
* use private docker registry for local development - to make things faster (kind 0.3 > does not play well with images from os x)

## priorities
* improve docs - wip
* provide hooks for `nixops` infra updates
* running cluster in `brigade` worker to test release - `dind`
* virtual kublet integration

### `gitops` via `brigade.js`
* make brigade responsible for a `k8s` resources update with `git commit`, `infra` updates with `nixops`

### optimalization
* optimize docker images
* push local store to s3

### provisioning
* provision `s3` bucket for cache in `aws-cdk` or `nixops`

### more investigation needed
* ability to define test for infrastructure and cluster, [more here](https://nixos.org/~eelco/talks/issre-nov-2010.pdf)
* https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/ccache.nix

### nice to have
* setup `nix-channel`
* [formatting](https://github.com/nixcloud/nix-beautify)

### DONE
* apply scripts from local shell to `nixos` cluster - done
* gitignore - https://nixos.org/nixpkgs/manual/#sec-pkgs-nix-gitignore