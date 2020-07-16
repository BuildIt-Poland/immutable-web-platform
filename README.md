`kiteloop`
Build and deploy anything everywhere. Project scaffolding and local development playground based on `nix`, `bazel` and `kubernetes` with predefined support to `haskel`, `java` and `nodejs`. 

### High level overview
* [Diagram](https://coggle.it/diagram/Xw660iV2w184ISI9/t/immutable-polyglot-platform/8f73a2a7499f44a188cece11044544f6c4cc52a52e9ce5e837203f440507b8fd)

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
* `nix-env -iA nixFlakes -f '<nixpkgs>'`

### To watch
* https://www.youtube.com/watch?v=mKXLAbrKrno

### Stack

#### Ops tools
* [`nix`](https://github.com/NixOS/nixpkgs) with [`flakes`](https://www.tweag.io/blog/2020-05-25-flakes/)
* [`dhall`](https://github.com/dhall-lang/dhall-lang) - configuration
* [`cachenix`](https://cachix.org/)
* [`nix-darwin`](https://github.com/LnL7/nix-darwin)
* [`lorri`](https://github.com/target/lorri) - droping in favour of `nix flakes`

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

#### More to read
* [nix flakes](https://zimbatm.com/NixFlakes/)

#### To consider
* embeding [`localstack`](https://github.com/localstack/localstack)

#### Issues
* `nix-darwin` permissions denied - run `sudo chown -R root:1 /nix/var` per this [issue](https://github.com/LnL7/nix-darwin/issues/188)
* `nix develop / shell` - does not work getting error related to `( )` - no idea, `--show-trace` shows nothing