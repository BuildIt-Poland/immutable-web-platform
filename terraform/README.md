### First steps
* create bucket for development and dynamodb table

### Kubectl
* `export KUBECONFIG=./.kube/kubeconfig_future-is-comming-local`

### Deploy cluster
* `terraform apply -target module.cluster`

### Shorthands
* `tf-project <project_name> <any_terraform_command>` - `project_name` means folder from terraform perspective, this is, we've got `terraform/aws/cluster` project in this case would be `aws/cluster`
* `tf-nix-exporter` -

### Nix exporter
* required `tf` definition
```tf
module "export-to-nix" {
  source = "../../modules/export-to-nix"
  data = {
    # TODO formatitng of yaml seems to be inccorect
    kubeconfig = yamldecode(module.cluster.eks.kubeconfig)
    bastion    = module.bastion.public_ip
    efs        = module.cluster.efs_provisoner.id
  }
  file-output = "${var.output_state_file["aws_cluster"]}"
}
```
* and then you can export via `tf-nix-exporter`
* examples: `aws/setup/main.tf` and `aws/cluster/main.tf`