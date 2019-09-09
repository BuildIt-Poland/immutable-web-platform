# https://www.openpolicyagent.org/docs/latest/how-do-i-write-policies/
package knative

deny[msg] {
  input.kind = "Service"
  not input.metadata.name
  msg = "Name has to be defined"
}