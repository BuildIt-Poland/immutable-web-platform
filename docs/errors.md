### Some issues / errors
* if you see `warning: skipped value for secrets: Not a table.` - don't worry, it is lying, it is related to brigade secrets and go unmarshaling, seems that k8s is not happy to have a hashmap instead of array, but `go` expect to have a `hashmap` - so all good!

* getting `error: a 'x86_64-linux' with features {} is required to build '/nix/store/vxwxcykyhdbiwyysj8fad14m0ynq6wlq-yarn.nix.drv', but I am a 'x86_64-darwin' with features {benchmark, big-parallel, nixos-test}
(use '--show-trace' to show detailed location information)`
> you need to run remote worker since most likely you are on darwin