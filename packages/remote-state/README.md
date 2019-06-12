# `remote-state`
Wrapper for any command which require some global state, to prevent changing resources at the same time. By me it is used to have a shared remote state for `nixops` something similar which you can find in `terraform` remote state.
Basically idea behind this is to provide changes to infrastructure from one source and do not allow do any other action whilist this action is not finished.

State is kept in `remote store` and locks are within `database`. 
For now, working variant is for `aws` (this is `s3` and `dynamodb`), but `azure` will be handled shortly.

### How it works
Each time when you run a `lock` state, `dynamodb` is adding record with information about lock. This information include data, such as, `who` (`AWS Access Id`), `timestamp`, `reason` - just to have clear view, who or what and why state was locked - if you are doing `upload-state` then lock is automatically handled, and will be unlocked as soon as operation finish - it will prevent some other resources to do a changes to shared resource, like for example infrastructure.
When state differs on `local` or `remote`, difference will be printed out to `stdout`, and you will be prompted to confirm whether you are happy with such merge.

### Commands
```
locker <command>

Commands:
  locker lock                Lock state
  locker unlock              Unlock state
  locker status              Get status of locker
  locker upload-state        Upload state
  locker has-remote-state    Checking existence of remote state on remote drive
  locker rewrite-arguments   Escape arguments for nixops
  locker download-state      Download state
  locker import-state        Import state
  locker diff-state <local>  Diff remote state with local state

Options:
  --version  Show version number                                       [boolean]
  --help     Show help                                                 [boolean]
```

### Example Usage
* `importing-state`
```bash
  locker import-state \
    --from "${nixops-export-state}" \        # importing state
    --before-to "${keep-nixops-stateless}" \ # removing state
    --to "${nixops-import-state}"            # exporting state
```

* `exporting-state`
```bash
  locker upload-state \
    --from "${pkgs.nixops}/bin/nixops export --all"
```

#### Full example
```nix
{
  pkgs ? import <nixpkgs> {}
}:
with pkgs;
let
  locker = remote-state.package.remote-state-cli;

  paths = {
    state-sql = "state.nixops";
  };

  keep-nixops-stateless = pkgs.writeScript "keep-it-stateless" ''
    rm ${paths.state-sql}
  '';

  nixops-export-state = pkgs.writeScript "nixops-export-state" ''
    ${pkgs.nixops}/bin/nixops export --all
  '';

  nixops-import-state = pkgs.writeScript "nixops-import-state" ''
    ${pkgs.nixops}/bin/nixops import --include-keys
  '';

  import-remote-state = pkgs.writeScriptBin "import-remote-state" ''
    ${locker}/bin/locker import-state \
      --from "${nixops-export-state}" \
      --before-to "${keep-nixops-stateless}" \
      --to "${nixops-import-state}"
  '';

  upload-remote-state = pkgs.writeScriptBin "upload-remote-state" ''
    ${locker}/bin/locker upload-state \
      --from "${pkgs.nixops}/bin/nixops export --all"
  '';

  nixops = pkgs.writeScriptBin "nixops" ''
    ${pkgs.nixops}/bin/nixops $(${locker}/bin/locker rewrite-arguments --input "$*" --cwd $(pwd))
  '';
in
mkShell {
  buildInputs = [
    upload-remote-state
    import-remote-state
    nixops
  ];
  NIX_PATH = "${./.}";
  NIXOPS_STATE = paths.state-sql;
  PROJECT_NAME = "my-project-name";
}
```