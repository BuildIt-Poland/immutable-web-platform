package main

test_metadata_name_defined {
  allow with input as {"metadata": {"name": "test"}}
}

test_metadata_name_not_defined {
  not allow with input as {"metadata": {"name": ""}}
}