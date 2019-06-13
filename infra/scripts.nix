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
  deploy-ec2 = deployment {
    name = "ec2";
    configuration = ./configuration.nix;
    machine = ./ec2.nix;
    resource-name = "buildit-ops"; # take from external config
  };

  deploy-vbox = deployment {
    name = "local-deployment";
    configuration = ./configuration.nix;
    machine = ./virtualbox.nix;
    resource-name = "buildit-ops"; # take from external config
  };
}