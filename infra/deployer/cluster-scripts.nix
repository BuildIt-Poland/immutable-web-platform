{
  nixops, 
  writeScript, 
  writeScriptBin, 
  rsync,
  lib,
  machines
}:
deployment-name: {
  join-to-cluster =
    let
      masters = builtins.attrNames machines.membership;
      concat = lib.concatMapStringsSep "\n";
      ops = "${nixops}/bin/nixops";
      safeEnvVar = builtins.replaceStrings ["-"] ["_"];
    in
      writeScriptBin "kubernetes-join-nodes-to-master" ''
        ${concat (master: 
          let
            name = safeEnvVar master;
            opsArgs = "-d ${deployment-name} $*";
          in
          ''
          COMMAND_${name}="$(${ops} ssh ${opsArgs} ${master} get-join-command)"
            ${concat 
              (node: ''${ops} ssh ${opsArgs} ${node} "$COMMAND_${name}"'') 
              (machines.membership.${master})
            }
          '') masters}
        '';
}