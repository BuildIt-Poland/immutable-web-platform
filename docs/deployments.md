* local development with vbox
nix-shell shell-infra.nix --arg local true

* provisioning
ssh to master -> `master-init` -> `apply-pod-network`
