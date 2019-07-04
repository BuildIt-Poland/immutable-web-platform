{ machinesConfigPath ? ./machines.json }:
let
  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);
in
  machines