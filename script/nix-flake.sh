
nix build -f channel:nixos-20.03 nixFlakes --out-link temp/nix

# # overriding existing nix command
export PATH="$PWD/temp/nix/bin:$PATH"