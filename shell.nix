{
  environment ? null,
  kubernetes ? null,
  opa ? null,
  brigade ? null,
  docker ? null,
  aws ? null,
  tests ? null,
  ...
}@inputs:
  import ./nix/run-shell.nix inputs