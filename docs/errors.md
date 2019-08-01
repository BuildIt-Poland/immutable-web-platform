### Some issues / errors
* if you see `warning: skipped value for secrets: Not a table.` - don't worry, it is lying, it is related to brigade secrets and go unmarshaling, seems that k8s is not happy to have a hashmap instead of array, but `go` expect to have a `hashmap` - so all good!

* getting `error: a 'x86_64-linux' with features {} is required to build '/nix/store/vxwxcykyhdbiwyysj8fad14m0ynq6wlq-yarn.nix.drv', but I am a 'x86_64-darwin' with features {benchmark, big-parallel, nixos-test}
(use '--show-trace' to show detailed location information)`

> you need to run remote worker since most likely you are on darwin

> solution: run `source run-linux-worker.sh`

* if your cluster is dying it seems that you have not sufficient resources for docker
> solution: https://bitbucket.org/digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative/issues/1/required-docker-resources-for-local

* Error getting host status: state: docker-machine-driver-hyperkit needs to run with elevated permissions. > solution: Please run the following command, then try again: sudo chown root:wheel /nix/store/3l4b2dqvdrlbikmdd7xiawmbrwiqgz3j-minikube-1.0.1-bin/bin/docker-machine-driver-hyperkit && sudo chmod u+s /nix/store/3l4b2dqvdrlbikmdd7xiawmbrwiqgz3j-minikube-1.0.1-bin/bin/docker-machine-driver-hyperkit

* building with kaniko and nix on mac os require adding /nix to shared path in docker