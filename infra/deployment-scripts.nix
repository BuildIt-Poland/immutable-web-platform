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
  # INFO
  # it is going to generate commands:
  # ops-deploy-ec2              
  # ops-delete-ec2              
  # ops-destroy-ec2             
  # ops-ssh-to-ec2-buildit-ops
  deploy-ec2 = deployment {
    name = "ec2";
    configuration = "infra/deployment.nix";
    machine = "infra/targets/ec2.nix";
    resource-name = "buildit-ops"; # take from external config
  };

  deploy-vbox = deployment {
    name = "local-deployment";
    configuration = "infra/deployment.nix";
    machine = "infra/targets/vbox-cluster.nix";
    resource-name = "buildit-ops"; # take from external config
  };
}