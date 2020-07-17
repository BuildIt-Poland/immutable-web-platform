nix build | cachix push polyglot-platform

# nix flake archive --json \
#   | jq -r '.path,(.inputs|to_entries[].value.path)' \
#   | cachix push $cache_name