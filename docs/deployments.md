### Nixops shell running

* local development with vbox
`nix-shell infra.nix --arg local true`

* ec2
`nix-shell infra.nix`

### One command deployemnt
`init-single-master-kubernetes`

### Commands available 

### `nixops`
* `kubernetes-join-nodes-to-master`

#### hosts
Flow: `creation -> node-joining -> provisioning`

#### Creation
* `master-init`
* `apply-pod-network`

#### Provisioning 
* `apply-cluster-stack`
* `apply-functions-to-cluster`
> There is a chance to enable `auto-provision` feature

#### Nixops remote state infra
* `remote-state-aws-stack`

#### Asking remote state
* `locker --help`