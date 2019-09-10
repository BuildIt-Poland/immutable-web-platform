package main
# TODO check terraform tags.Owner
# https://github.com/instrumenta/conftest/tree/master/examples/terraform\
# terraform plan show --json plan > show

# blacklist = [
# ]

# deny[msg] {
#   check_resources(input.resource_changes, blacklist)
#   banned := concat(", ", blacklist)
#   msg = sprintf("Terraform plan will change prohibited resources in the following namespaces: %v", [banned])
# }

# check_resources(resources, disallowed_prefixes) {
#   startswith(resources[_].type, disallowed_prefixes[_])
# }