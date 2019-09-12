package mixerauthz

default allow = false

# express-app.dev-functions.future-is-comming.dev.local

allow {
  input.subject.user == "damian"
}

# allow {
#   input.action.namespace = "istio-system"
# }

allow {
  contains(input.action.path, "/healthz")
  # allowed_targets = connectivity[istio_attrs.source_service
  # istio_attrs.dest_service = allowed_targets[_]
}

# If access is from internal service
# allow {

# }