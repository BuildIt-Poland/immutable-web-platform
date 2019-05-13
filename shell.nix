let
  pkgs = import ./nix {};
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  nativeBuildInputs = [
  ];

  buildInputs = [
    pkgs.yarn2nix
  ];

  shellHook= ''
  '';
}