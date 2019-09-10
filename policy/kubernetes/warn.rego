package main

import data.kubernetes_types

name = input.metadata.name

warn[msg] {
  kubernetes_types.is_service
  msg = sprintf("Found service %s but services are not allowed", [name])
}