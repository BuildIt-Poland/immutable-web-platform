`kiteloop`
Build and deploy anything everywhere. Project scaffolding and local development playground based on `nix`, `bazel` and `kubernetes` with embeded support to `haskel`, `java`.

### Goal
* make configuration sane, scalable and type safe
* how `nix` can be used for `local development`
* automation with `nix`, `bazel` & `kubernetes`

### Before start 
#### Prerequisites
* `nix`
* `direnv`
* `cachenix` - `nix-env -iA cachix -f https://cachix.org/api/v1/install`
> public key: polyglot-platform.cachix.org-1:87XRS0rO9Qgk+cQDg4AGooa9VBRbb/mGvMfXwVRYh1c=

### To watch
* https://www.youtube.com/watch?v=mKXLAbrKrno

### Stack

#### Ops tools
* [`nix`](https://github.com/NixOS/nixpkgs) with [`flakes`](https://www.tweag.io/blog/2020-05-25-flakes/)
* [`dhall`](https://github.com/dhall-lang/dhall-lang) - configuration
* [`cachenix`](https://cachix.org/)
* [`lorri`](https://github.com/target/lorri)

#### Dev tools
* `bazel`
*

### Infra
* `kubernetes`
* `kafka`

#### Languages
* `java`
* `haskell`

#### IDE
* `haskell` - `ghcide` - `nix-env -iA haskellPackages.ghcide -f '<nixpkgs>'`

### TODO
* `nixpkgs` - pin `bazel` & `nix` to the same version
* handle `lorri shell --cached`
* vscode -> [`dhall-lsp-server`](https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server)