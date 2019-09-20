## Nix-channel
There is a `binary` store / private `nixpkgs` repo to avoid rebuilding too much.

To enable go with below:

> Adding [`channel`](https://hydra.future-is-comming.dev.buildit.consulting/channel/custom/future-is-comming/binary-store/channel)
* `nix-channel --add https://hydra.future-is-comming.dev.buildit.consulting/job/future-is-comming/binary-store/channel/latest/download/1 buildit`
* `nix-channel --update`

> Installing from channel
* `nix-env -iA buildit.brigadeterm`

> Referencing in `nix` expression
* `<buildit>