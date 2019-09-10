# https://www.openpolicyagent.org/docs/latest/how-do-i-write-policies/
package main

deny["knative.service"] {
  input.kind == "Service"
  input.metadata.name == ""
  msg = "Name has to be defined"
}