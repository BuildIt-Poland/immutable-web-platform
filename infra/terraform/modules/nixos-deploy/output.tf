# without this get cyclic error - investigate - in the middle of imports
output "nixos_path" {
  value = data.external.nixos-build.result
}
