package mixerauthz

import data.nix

default allow = false

allowed_paths = {"/healthz"}
# # express-app.dev-functions.future-is-comming.dev.local

allow {
  input.subject.user == "caller"
  contains(input.action.service, nix.ns.functions)
}

allow {
  # allowed_paths[http_request.path]
  allowed_paths[input.action.path]
  # net.cidr_contains("CIDDR", source_address.Address.SocketAddress.address)
}