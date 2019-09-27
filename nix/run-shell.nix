# FIXME add optional pkgs
{name ? "λ", ...}@inputs:
let
  pkgs = (import ./. { inherit inputs; }).pkgs;
  name = "#shell#${pkgs.project-config.environment.perspective}#${name}";
in
with pkgs;
  mkShell ({
    NIX_SHELL_NAME = name;
    # https://github.com/target/lorri/issues/98
    # SSL_CERT_FILE = "~/.nix-profile/etc/ssl/certs/ca-bundle.crt";
    # NIX_SSL_CERT_FILE = "~/.nix-profile/etc/ssl/certs/ca-bundle.crt";
    buildInputs = project-config.packages ++ [ pkgs.lorri pkgs.direnv ];
    shellHook= project-config.shellHook;
  } // project-config.environment.vars)