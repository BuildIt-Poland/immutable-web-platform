## Today
* consider `tekton`
* add depends_on to bootstrap - changing instance should rerun bootstrap
* config generation
* expose kibana - separate chart - test on eks
* not sure why aws secret patch is shouting ...
* fix apply-aws-credenitials-secret -> required by brigade 
* https://github.com/open-policy-agent/opa-istio-plugin
* validate before saving yaml resource - fail quickly
* think about keeping pipeline close to project itself -> allow to inject module from function pespective
* consider to use kubernetes patches like this https://www.diycode.cc/projects/Azure/kubernetes-policy-controller
* spinup binary cache - after building go packages it takes time ... -> need to have hydra instance
* add metadata.env
* add namespace for functions
* istio faul-injection as mocks
### in progress
* setup bastion on nixos -> restic, velero, kubectl
* https://github.com/kubernetes/autoscaler/issues/2246 - waiting for september
* shell for infra is necessary - nix shell infra first to bootstrap env and export outputs from terraform after that ... nix with resources
* tests and functions should be run in spot instances
* istio / autscaller run on main instance -> nodeSelector / nodeAffinity
* enum for fs types - aws-efs

- create autoscalling groups (https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md) - done
- https://github.com/rook/rook/tree/master/cluster/examples/kubernetes/ceph
- add taints - think about best strategy for testing and app perfomance
- make PR to brigade to be able to select nodeSelector - required to spawn tests on spot instances

### doing
* finish minikube regression and do some smoke tests on eks

### regression:
* SSL with istio and EKS - aws_route_53 - partially done
* refactor env -> should be more like dev, staging, qa, prod - local and current usage is a bit unclear (i.e. it would be handy to use for ssl -> certificate -> lets encrypt)
* change integration-modules to configuration-modules, and kubenix-modules to kubernetes-modules, prepare virtual-services for local and cloud env (hosts related)

### works:
- build go packages instead of using binaries - required by targeting linux within bastion - all go packages are built thru nix
- (kubernetes.target (minikube/eks/aks), environement.runtime (local, ci), environement.type 'dev','staging','prod')
* prometheus metrics and grafana dashboard for ceph
* velero - backups - auto at least before resources to rollback quickly
* spin up bitbucket gateway with AWS LB - virtual service and SSL is there
* virtual-services does not work
* rook-ceph with dashboard
* task to generate kubeconfig from terraform (
  terraform apply -target module.cluster.module.eks.local_file.kubeconfig) - `tf-nix-exporter`
* Terraform eks cluster [
- create aws role to attach for KMS and BinaryStore + kms generation from nixops or terraform
- create eks cluster
- trying to keep terraform dry - autogenerating varfiles and variables json to avoid duplicating code related to vars - tf-project bash command + var generator
- docker images -> EKS (https://kubernetes.io/docs/concepts/containers/images/#using-amazon-elastic-container-registry)
- virtual services works - one LB will sufice
- pvc for brigade project - done -> rook ceph

-----
* nix copy-sigs - brigade

* integration-modules -> run cluster on virtualbox with integration-modules attached
* allow to define virtual services within environement config
* refactoring -> create `kubectl-helpers` -> create `bootstrap-module` - (shape is there)
* remove errors found by argo (zipkin 2x, local-infra ns 2x, functions 2x) - test -> should be ok
----
* define brigade project within config/environement-setup rather that in brigade module
* move git commands from shell to nix module
* enable kashti
* add ability to handle secrets in similar manner as other kubenretes resources but with extra script - patch phase
* move nix stuff to module pattern
* brigade setup -> running nix tests
* think about getting rid of eval minikube docker-env
* improve readability what is going on when starting cluster
* introduce better control over granularity related to kubernetes resources
* introduce more distinctive parts for kubernetes resources (cluster, monitoring, faas, application, etc.) - move argo to separate resource to avoid chicken egg problem
* minikube and pvc and SC for brigade
* export aws variables - do not keep them within secret
* generate resources to file and check --local --watch `argocd app diff my-app` -> `argocd app diff $PROJECT_NAME --local ./resources`
* portmapping for monitoring is done, do the same for istio (port-forwarding will be unnecessary and all environment will have the same way of exposing external ports)
* create argo startup scripts
* figure out better invalidation -> nix is doing a hash from directory, so move baking the image to some other place
* integrate `istioctl` - create derivation
* each time dockerTools.buildImage is run even if contents won't change it is invoked - in case of development it is a bit painful

WHY it was needed: keeping secrets and improving granularity to not kill the argo

----
# try to setup local env with buildkit - much faster builds
research -> https://gist.github.com/damianbaar/7194251de2b6f64af459ac861d34a323

## TODO
* populate docker registry or nixos docker repository
* align ec2 deployment to `machine.json` descriptor
* run example tests agains artifact in brigade
* watch github hooks when approving the pull request
- define argo waves - order of deployment

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
* add skip flag for resources like secrets [
  - think about detecting empty resources during generation - minor - filter them out? 
  -`Error from server: error decoding from json: illegal base64 data at input byte 0` - don't apply secrets
  - module is referencing generated secret - but secret does not need to be applied - skip when applying would be enough
]
* apply scripts from local shell to `nixos` cluster - done
* gitignore - https://nixos.org/nixpkgs/manual/#sec-pkgs-nix-gitignore
* setup brigade (serviceaccount) to be able to operate on kubernetes cluster (partially done - custom binding is there)
* use private docker registry for local development - to make things faster (kind 0.3 > does not play well with images from os x) (wip)
* forward `kubenix` results to brigade workers
* create repository for infra code
* architecture diagram v0.0.1
* make diffing of resources possible - argo is doing that
* argo ingress to avoid issue with https - passhtrough from istio

### Goal
* deploy `https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/` - I need to have something to work with `knative` as a project sounds good
* spin up `distributed build cache` - to make building and provisioning super fast
* spin up `brigade.js` to not using any `CI` solution - architecture should be event driven
* spin up `k8s cluster` on `ec2` not `eks` - just to try alternative solution which has less assumptions from vendor
* make infrastructure testable, ...[more](https://nixos.org/nixos/manual/index.html#sec-nixos-tests)

#### Some whys
* why there are 2 CI systems - hydra and `brigade`
> I was playing only with brigade and it assumes to many custom scripts related to updating the binary store, number of plugins is growing fast and it is painful to build it every time, this is where `hydra` comes in - gives ability to create a channel which can be latter used by other person - it will save tons of build time. `hydra` also allows build `tar` which can be helpful in case of `packages` as well as be a `binary-store`. 
> Brigade is great to response to events with CI flavour, building artifacts is okey, but in case of integration with `nix` and heavy load it is not a best fit, also brigade run within cluster, `hydra` outside.
> Another point is related to disk usage - sometimes cache can grow so no point to keep it locally.