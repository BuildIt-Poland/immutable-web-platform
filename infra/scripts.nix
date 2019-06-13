{nixops, writeScript, writeScriptBin}:
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

    make-ssh = writeScriptBin "ops-ssh-to-${name}-${resource-name}" ''
      ${nixops}/bin/nixops ssh -d ${name} ${resource-name}
    '';
  };
in
{
  # TODO think whether rewriting is args in shell-infra is necessary
  # either will keep paths like below from root of monorepo
  # or enable rewriting - without rewriting all is cleaner
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