let
  pkgs = (import ./nix {}).pkgs;
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  buildInputs = [
    nodejs
    pkgs.yarn2nix.yarn
    pkgs.functions.scripts.build-and-push
  ];

  shellHook= ''
  '';
}