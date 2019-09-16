package mixerauthz

import data.nix

default allow = false

allowed_paths = {"/healthz"}

allowed_namespaces = {
  nix.ns.istio,
  nix.ns["knative-monitoring"],
  nix.ns["knative-serving"]
}

allow {
  input.subject.user == nix.config["authorEmail"]
  contains(input.action.service, nix.ns.functions)
}

allow {
  allowed_paths[input.action.path]
  # net.cidr_contains("CIDDR", source_address.Address.SocketAddress.address)
}

allow {
  allowed_namespaces[input.action.namespace]
  input.action.method == "GET"
}