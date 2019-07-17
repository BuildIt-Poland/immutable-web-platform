## TODO
* populate docker registry or nixos docker repository
* make diffing of resources possible
* align ec2 deployment to `machine.json` descriptor
* run example tests agains artifact in brigade
* watch github hooks when approving the pull request
* portmapping for monitoring is done, do the same for istio (port-forwarding will be unnecessary and all environment will have the same way of exposing external ports)
* introduce more distinctive parts for kubernetes resources (cluster, monitoring, faas, application, etc.) - move argo to separate resource to avoid chicken egg problem
- create argo startup scripts

* refactoring -> create `kubectl-helpers` -> create `bootstrap-module` - (shape is there)

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
* setup brigade (serviceaccount) to be able to operate on kubernetes cluster (partially done - custom binding is there)
* use private docker registry for local development - to make things faster (kind 0.3 > does not play well with images from os x) (wip)
* forward `kubenix` results to brigade workers
* create repository for infra code
* architecture diagram v0.0.1

### Goal
* deploy `https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/` - I need to have something to work with `knative` as a project sounds good
* spin up `distributed build cache` - to make building and provisioning super fast
* spin up `brigade.js` to not using any `CI` solution - architecture should be event driven
* spin up `k8s cluster` on `ec2` not `eks` - just to try alternative solution which has less assumptions from vendor
* make infrastructure testable, ...[more](https://nixos.org/nixos/manual/index.html#sec-nixos-tests)