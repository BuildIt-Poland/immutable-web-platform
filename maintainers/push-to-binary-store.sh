nix copy \
  --to 's3://future-is-comming-worker-binary-store?region=eu-west-2' \
  $(nix-store -qR --include-outputs \
    $(nix-instantiate shell.nix \
      --arg kubernetes '{update=true;}' \
      --arg docker '{upload=false;}' \
      --arg tests '{enable=true;}' \
      --add-root ./result --indirect))