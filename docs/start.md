### Prerequisites
#### You need to install these
* get [`docker`](https://www.docker.com/products/docker-desktop) for `minikube`.
* get [`nix`](https://nixos.org/nix/download.html) - creating isolated local environment and package management

### Steps
* when deploying to `eks` or `aks` or `gcp` create infrastructure first
* fulfill `prerequisites`
* run `nix-shell` with appropriate target

### Quick start
* run `run-shell-with-worker.sh` 
> it is going to install `nix-remote-worker` - necessary to build `docker` without `daemonless` on `linux` machine

### Running targets
#### `nix-shell` running options
```bash
nix-shell \
  --arg kubernetes '{target="<minikube|eks|aks|gcp>"; clean=true; save=true; update=true; patches=true;}' \
  --arg docker '{upload=true;}'
```

#### Meaning
* `clean` - whether to apply and wait for `crd` - when starting first time it has to be `true`
* `save` - whether should save all generated `kubernetes` resources to `resource` folder
* `update` - whether should apply all `kubernetes` resources
* `pathches` - whether should run patches on kubernetes resources - when more interaction with external services is required

#### All options
* you can check defaults or create new one it is fully extensible and can be seen [here](/nix/targets/defaults.nix)

### Creating infrastructure
#### Provisioning infra with `terraform`
* follow [`terraform guid`](/docs/terraform.md) only `minikube` provisioning is `automated` with `nix`.

#### Applying `kubernetes` resources
#### Configuration
##### Minikube
* running `minikube` - `nix-shell --arg kubernetes '{target="minikube"; clean=true; save=true; update=true; patches=true;}' --arg docker '{upload=true;}'`
> `minikube` will create cluster if not exists

##### EKS
* `eks` - `nix-shell --arg kubernetes '{target="eks"; clean=true; save=true; update=true; patches=true;}' --arg docker '{upload=true;}'`

##### AKS
* TODO

Provisioning takes couple of minutes so after running, you can go for a coffee - start watcher to know what happen `kubectl get pods -Aw`.

### Infra deployment
#### EKS
* `tf-project aws/setup init`

### Secrets
File with secrets, this is `secret.json` is created after `infra` deployment as we need to have `kms` key. It implies that destroying key destroy secrets as well.

#### Required secrets
##### Bitbucket
* `secret` -> XHookUUID request

### Shorthands helpful at the beginning
#### Wait for kubernetes
* to check status you can run `kubectl get pods -Aw` - wait until everything will be running

#### If running `minikube` 
##### Getting all available services
* `minikube service list -p $PROJECT_NAME`


### Errors
* if you encounter any issues check [docs](/docs/errors.md)
