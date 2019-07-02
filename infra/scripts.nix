{nixops, writeScript, writeScriptBin, rsync}:
let
  deployment = {name, configuration, machine, resource-name}: rec {
    create = writeScriptBin "create-deployment-${name}" ''
      ${nixops}/bin/nixops list | grep "${name}" || \
        ${nixops}/bin/nixops create ${configuration} ${machine} -d ${name}
    '';

    destroy = writeScriptBin "ops-destroy-${name}" ''
      ${nixops}/bin/nixops destroy -d ${name}
    '';

    delete = writeScriptBin "ops-delete-${name}" ''
      ${destroy}/bin/${destroy.name}
      ${nixops}/bin/nixops delete -d ${name}
    '';

    deploy = writeScriptBin "ops-deploy-${name}" ''
      ${create}/bin/${create.name}
      ${nixops}/bin/nixops deploy -d ${name} --kill-obsolete
    '';

    copy-contents = writeScriptBin "ops-folder-sync-${name}" ''
      ${rsync}/bin/rsync --rsh="${make-ssh}/bin/${make-ssh.name}" $*
    '';

    make-ssh = writeScriptBin "ops-ssh-to-${name}-${resource-name}" ''
      ${nixops}/bin/nixops ssh -d ${name} ${resource-name}
    '';
  };
in
{
  # TODO copy secret to workers
  # nixops ssh -d cluster master-0 "cat  /var/lib/kubernetes/secrets/apitoken.secret"
  # nixops ssh -d cluster worker-0 "echo $token | nixos-kubernetes-node-join"
  # nixops ssh -d cluster worker-0 "echo $(nixops ssh -d cluster master-0 'cat /var/lib/kubernetes/secrets/apitoken.secret') | nixos-kubernetes-node-join"

  # TODO think whether rewriting is args in shell-infra is necessary
  # either will keep paths like below from root of monorepo
  # or enable rewriting - without rewriting all is cleaner

  # INFO
  # it is going to generate commands:
  # ops-deploy-ec2              
  # ops-delete-ec2              
  # ops-destroy-ec2             
  # ops-ssh-to-ec2-buildit-ops
  deploy-ec2 = deployment {
    name = "ec2";
    configuration = "infra/configuration.nix";
    machine = "infra/ec2.nix";
    resource-name = "buildit-ops"; # take from external config
  };

  deploy-vbox = deployment {
    name = "local-deployment";
    configuration = "infra/configuration.nix";
    machine = "infra/virtualbox.nix";
    resource-name = "buildit-ops"; # take from external config
  };
}