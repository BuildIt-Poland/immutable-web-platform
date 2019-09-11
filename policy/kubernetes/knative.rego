# https://www.openpolicyagent.org/docs/latest/how-do-i-write-policies/
package main

deny[msg] {
  match
  not any_name
  msg := "Missing name, define metadata.name"
}

deny[msg] {
  match
  not any_env
  msg := "Missing env, define metadata.labels.env"
}

deny[msg] {
  match
  not any_namespace
  msg := "Missing namespace, define metadata.namespace"
}

any_name {
  input.metadata.name != ""
}

any_namespace {
  input.metadata.namespace != ""
}

any_env {
  input.metadata.labels.env != ""
}

match {
 	is_service
  is_knative_resource
}

is_service() {
	input.kind = "Service"
}

is_knative_resource = output {
  output = contains(input.apiVersion, "knative.dev")
}
