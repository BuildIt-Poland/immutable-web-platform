let
  pkgs = import ./nix {};
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  buildInputs = [
    nodejs
    pkgs.yarn2nix.yarn
    pkgs.functions.express-app.package
  ];

  shellHook= ''
  '';
}