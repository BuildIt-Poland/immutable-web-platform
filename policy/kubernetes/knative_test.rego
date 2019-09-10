package main

test_metadata_name_not_defined {
  deny["knative.service"] with input as {"metadata": {"name": ""}, "kind": "Service"}
}

test_metadata_name {
  not deny["knative.service"] with input as {"metadata": {"name": "dsada"}, "kind": "Service"}
}