{sources}:
self: super: rec {
  # INFO when calling skaffold - showing incorrect version
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/skaffold/default.nix#L14
  skaffold = super.skaffold.overrideAttrs (oldAttrs: rec {
    version = "0.34.0";
    name = "skaffold-${version}";
    rev = "ffd0608298e38df00795660ca45d566b4f94fab0";
    src = super.fetchFromGitHub {
      inherit rev;
      owner = "GoogleContainerTools";
      repo = "skaffold";
      sha256 = "1d7zfyjqi0qvsz82ngfs7wvsnz1h068qgavcp07842cypar2xwcl";
    };
  });
}