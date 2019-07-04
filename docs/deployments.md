### Nixops shell running
* local development with vbox
nix-shell shell-infra.nix --arg local true


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
