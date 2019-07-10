{
  nixops, 
  writeScript, 
  writeScriptBin, 
  rsync,
  lib,
  machines
}:
deployment-name: 
let
  ops = "${nixops}/bin/nixops";
  opsArgs = "-d ${deployment-name} $*";
  run-ssh = "${ops} ssh ${opsArgs}";
in
rec {
  join-to-cluster =
    let
      masters = builtins.attrNames machines.membership;
      concat = lib.concatMapStringsSep "\n";
      safeEnvVar = builtins.replaceStrings ["-"] ["_"];
    in
      writeScriptBin "kubernetes-join-nodes-to-master" ''
        ${concat (master: 
          let
            name = safeEnvVar master;
          in
          ''
          COMMAND_${name}="$(${run-ssh} ${master} get-join-command)"
            ${concat 
              (node: ''${run-ssh} ${node} "$COMMAND_${name}"'') 
              (machines.membership.${master})
            }
          '') masters}
        '';

    # TODO implement multimaster
    # TODO take command names from nix-expression rather magic strings
    run-kuberetes-single-master = 
      let
        master-name = builtins.elemAt (builtins.attrNames machines.membership) 0;
        run-on-master = "${run-ssh} ${master-name}";
      in
      writeScriptBin "init-single-master-kubernetes" ''
        echo "Initializing master"
        ${run-on-master} master-init
        ${run-on-master} apply-pod-network

        echo "Joining clusters"
        ${join-to-cluster}/bin/${join-to-cluster.name}
      '';
}