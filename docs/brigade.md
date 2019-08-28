### gateway
* bitbucket -> https://github.com/lukepatrick/brigade-bitbucket-gateway
* i.e. `https://bitbucket-gateway.services.future-is-comming.dev.buildit.consulting/events/bitbucket`

#### in progress ...

### running project with custom js file
* `brig run -f pipeline/infrastructure.js  $BRIGADE_PROJECT`

### displaying job status in cli
* `brigadeterm`

### Important
if you want to test pipeline, integration is not necessary, run is sufficient.

### setup with bitbucket
* run `create-localtunnel-for-brigade`
* run `nix-shell` with `sharedSecret`, like so`nix-shell --argstr brigadeSharedSecret "XXXXXX-XXXX-XXXX-XXXX-XXXXXXXX"`
* setup `bitbucket` `webhook`
* setup `bitbucket` access key
* create `ssh` key for `bitbucket` and add `pub` to `access key`
* private key will be used by `brigade` and expect to be in `~/.ssh/brigade_integration`
