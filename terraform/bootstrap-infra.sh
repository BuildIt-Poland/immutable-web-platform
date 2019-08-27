# TODO
run_shell() {
  nix-shell $*
}

nix-shell \
  --arg kubernetes '{target="eks"; clean=false; save=true; update=false; patches=false;}' \
  --arg docker '{upload=false;}' \
  --arg tests '{enable=false;}' \
  --command 'tf-project aws/cluster apply'