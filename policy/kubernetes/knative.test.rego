package main

test_all_good {
  deny with input as createInput("test", "test", "test") == false
}

test_missing_name {
  deny with input as createInput("test", "test", "")
  deny with input as createInput("test", "", "")
  deny with input as createInput("", "", "")
}

createInput(name, namespace, env) = output {
  output := {
    "metadata": {
      "name": name, 
      "namespace": namespace,
      "labels": {
        "env": env
      }
    }, 
    "kind": "Service", 
    "apiVersion": "serving.knative.dev/v1alpha1"
  }
}