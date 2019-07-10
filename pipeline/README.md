### Testing worker shell
* just run `nix-shell` all what is available in normal shell here would be available as well

### Running pipeline
* `brig run -f pipeline/infrastructure.js  $BRIGADE_PROJECT`

#### IMPORTANT 
* nix is lazy so we can require whole ./nix folder and reuse the scripts - awesome isn't it?

### Testing shell
* `nix-shell -A shell`

### Testing worker script
* `BRIGADE_BUILD_NAME=local-build nix-shell -A shell --run make-pr-with-descriptors`