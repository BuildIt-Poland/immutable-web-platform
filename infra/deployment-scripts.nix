# Generated commands:
# ops-deploy-ec2              
# ops-delete-ec2              
# ops-destroy-ec2             
# ops-ssh-to-*
{
  nixops, 
  writeScript, 
  writeScriptBin, 
  rsync,
  lib,
  machines
}:
let

  create-ssh-variants = let
    make-ssh = name: resource-name: 
      writeScriptBin "ops-ssh-to-${name}-${resource-name}" ''
        ${nixops}/bin/nixops ssh -d ${name} ${resource-name}
      '';

    masters = (builtins.attrNames machines.membership) ;
    nodes = 
      (lib.flatten 
          (lib.foldl 
            builtins.concatLists 
            (builtins.attrValues machines.membership) 
            []));
  in
    name: 
      lib.genAttrs  
        (masters ++ nodes) 
        (make-ssh name);

  deployment = {name, configuration, machine}: rec {

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

      # copy-contents = writeScriptBin "ops-folder-sync-${name}" ''
      #   ${rsync}/bin/rsync --rsh="${make-ssh}/bin/${make-ssh.name}" $*
      # '';
    } // (create-ssh-variants name);
in
{
  deploy-ec2 = deployment {
    name = "ec2";
    configuration = "infra/deployment.nix";
    machine = "infra/targets/ec2.nix";
  };

  deploy-vbox = deployment {
    name = "local-deployment";
    configuration = "infra/deployment.nix";
    machine = "infra/targets/vbox-cluster.nix";
  };
}