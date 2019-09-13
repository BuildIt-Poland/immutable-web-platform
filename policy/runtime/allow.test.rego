package mixerauthz

import data.nix

test_data_nix {
  nix.ns.functions == "dev-functions"
}

test_allow {
  allow with input as { 
    "subject": { "user": "caller" }, 
    "action": { "service": "*.dev-functions"}
  }
}

test_deny {
  not allow with input as { 
    "subject": { "user": "any_other" }, 
    "action": { "service": "*.dev-functions"}
  }
}