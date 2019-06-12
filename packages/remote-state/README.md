# `remote-state`
Wrapper for any command which is able to export the state of infrastructure and do a lock during deployment.
Pluggable into `aws` and `azure`.

# Commands
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

# Example Usage
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