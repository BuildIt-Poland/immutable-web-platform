### Testing worker shell localy
* just run `nix-shell --arg local true` all what is available in normal shell here would be available as well

### Running pipeline
* `brig run -f pipeline/infrastructure.js  $BRIGADE_PROJECT`

#### IMPORTANT 
* nix is lazy so we can require whole ./nix folder and reuse the scripts - awesome isn't it?

### Testing shell
* `nix-shell -A shell`

### Testing worker script
* `BUILD_ID=local-build nix-shell -A shell --run make-pr-with-descriptors`

### Repo with infra
* https://bitbucket.org/damian_baar/k8s-infra-descriptors