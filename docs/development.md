## How to
### Running clean cluster
* `nix-shell --arg fresh true --arg uploadDockerImages true`

> These ... below are already integrated with nix-shell! in case of local environment cluster is provisioned automatically, you can rerun using `push-docker-images-to-local-cluster`

### Setup brigade
* generate `ssh-key` only for your `bitbucket` hook. named your key as `bitbucket-webook` and place in `~/.ssh/` folder - (no worries, it can be changed in `nix/default.nix`)

### Start
### Required
* [`nixpkgs`](https://nixos.org/nix/download.html)
* [`nixops`](https://nixos.org/nixops/manual/#chap-installation) - `nix-env -i nixops`
* [`docker`](https://www.docker.com/get-started) - for local development

#### When developing
* if you are on `os x` enable `remote-worker`, more in [Building docker with nix on `mac`](#Building-docker-with-nix-on-mac)
* run `nix-shell`
#### or ... for pleasant development with watch
* run `nix-env -if ./nix/external/direnv.nix` - more about [`direnv`](https://direnv.net/)
* run `nix-env -if nix/external/lorri`

### Infrastructure provisioning
#### Why
Test localy on `virtualbox`, deploy to `aws` or `azure` latter on.

#### Creating deployment
* `cd infra`
* check `Makefile`

#### Running integration tests
* `nix-build release.nix -A integrationTest` - only on `nixos`, however not worries, already got that, you can run it from infra/Makefile

#### Loggin into the `nixos` `virtualbox`
* `nixops ssh -d <deployment_name>`
* changing password (if you want to play in non headless mode) `passwd`

#### Starting local env
* you can start `nix-shell`

or super fancy `lorri` with watch capability (check required section)
* `lorri shell` ()

### Building docker with nix on `mac`
* setup a `builder` - by running command within your shell (before you run nix-shell) `source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)`
> This script going to download docker worker as well as setup some keys and export env var related to builder (`NIX_REMOTE_SYSTEMS`), however if you will go with new shell over and over again, you can re-run the script or, build with `--builders`, like so `nix-build <your-build.nix> --builders 'ssh://nix-docker-build-slave x86_64-linux'`

### Setup local brigade
* run `create-localtunnel-for-brigade`
* after that you will get tunel, create webhook `https://tricky-grasshopper-9.localtunnel.me/events/bitbucket/`
* if you want to have auto-brigade configuration you have to pass `brigadeSharedSecret`, like so
`nix-shell --argstr brigadeSharedSecret "<bitbucket.webhooks.request.X-Hook-UUID>"`

### Important
* when pushing to docker registry, provide your [credentials](https://github.com/containers/skopeo#private-registries-with-authentication) - on `os x` auth via `keychain` does not work - simple workaround is to delete `credStore` do the login and should be all good.

### Performance
* if you want to speed up `nix` a bit you can leverage `--max-job` params

### Building images from derivation
* `nix-build nix -A functions.express-app.images --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`
* `docker load < result`
* and then `docker run -it <container_id> /bin/sh`

### Pushing `docker-image`
* `nix-build nix -A functions.express-app.pushDockerImages --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true`