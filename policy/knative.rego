# https://www.openpolicyagent.org/docs/latest/how-do-i-write-policies/
package main

deny[msg] {
  input.kind = "Service"
  not input.metadata.name
  msg = "Name has to be defined"
}