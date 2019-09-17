{ supportedSystems ? ["x86_64-linux"] }:

with (import <nixpkgs/pkgs/top-level/release-lib.nix> { inherit supportedSystems; });
{
  hello_world = pkgs.lib.genAttrs supportedSystems (system: (pkgsFor system).hello);
} // mapTestOn {

  # Fancy shortcut to generate one attribute per supported platform.
  # hello = hello_world;

}