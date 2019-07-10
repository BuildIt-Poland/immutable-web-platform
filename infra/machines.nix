{ machinesConfigPath ? ./machines.json }:
let
  machines = builtins.fromJSON (builtins.readFile machinesConfigPath);
in
  machines

# TODO expose some extra methods -> get all nodes -> required by ssh