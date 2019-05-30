### How secrets works
we've got one file in repo called `secrets.json`, for `brigade secret` purposes, whole file is forwarded as `secret` to `brigade` project. Worker gets `aws-details` so using `kms` is able to `decrypt` file via `sops`.

### Editing secrets
* within `nix-shell` run `sops secrets.json` - will provide extra script for it latter (#TODO)

### keeping secrets in git
As docker credentials files are rubbish, there is a secret integration with [`sops`](https://github.com/mozilla/sops). It allow to integrate with all cloud providers. I believe (at least for now) that keeping master password in cloud provider is way to go. Another way would be to go with `gpg` but I want to expect from anyone to install it to start.

### things to consider
* key rotation


* for [AWS](https://github.com/mozilla/sops#25kms-aws-profiles)

### How it work
it is only fetched at beginning.

### Some reads
* * https://opensource.com/article/19/2/secrets-management-tools-git

### To consider 
* https://github.com/StackExchange/blackbox
* https://github.com/AGWA/git-crypt
> but ... cases like rotation/ /when someone is leaving might be trickier