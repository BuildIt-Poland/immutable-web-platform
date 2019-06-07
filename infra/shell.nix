{
  pkgs ? import <nixpkgs> {},
  kms
}:
with pkgs;
let
  encode-state = pkgs.writeScript "encode-state" ''
    ${pkgs.sops}/bin/sops --kms ${kms} -e localstate.nixops > infra.state
  '';

  decode-state = pkgs.writeScript "decode-state" ''
    ${pkgs.sops}/bin/sops -d infra.state > localstate.nixops
  '';

  nixops-with-state = pkgs.writeScriptBin "nixops" ''
    ${decode-state}
    ${pkgs.nixops}/bin/nixops $* --state localstate.nixops
    ${encode-state}
  '';

  # TODO port make scripts here
  # TODO compare states
in
mkShell {
  buildInputs = [
    nixops-with-state
    pkgs.sops
  ];
  shellHook = ''
  '';
}