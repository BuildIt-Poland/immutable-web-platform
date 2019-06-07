{
  pkgs ? import <nixpkgs> {},
  kms
}:
# TODO
# export state to bucket
# load state
with pkgs;
let
  encode-state = pkgs.writeScript "encode-state" ''
    ${pkgs.sops}/bin/sops --kms ${kms} -e localstate.nixops > infra.state
  '';

  decode-state = pkgs.writeScript "decode-state" ''
    ${pkgs.sops}/bin/sops -d infra.state > localstate.nixops
  '';

  ops-with-state = pkgs.writeScriptBin "ops" ''
    ${decode-state}
    ${pkgs.nixops}/bin/nixops $* --state localstate.nixops
    ${encode-state}
  '';

in
mkShell {
  buildInputs = [
    ops-with-state
    pkgs.sops
  ];
  shellHook = ''
  '';
}