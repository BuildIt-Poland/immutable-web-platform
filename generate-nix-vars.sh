nix-shell \
  --arg kubernetes '{target="eks"; save=false; update=false; patches=false;}' \
  --arg docker '{upload=false;}' \
  --arg tests '{enable=false;}' \
  --command 'tf-nix-exporter aws/cluster'