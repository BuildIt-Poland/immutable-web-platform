{pkgs}:
let 
in
{
  dhallToNix = code :
  let
    file = builtins.toFile "dhall-expr" code;

    drv = pkgs.stdenv.mkDerivation {
      name = "dhall-expr-as-nix";

      buildCommand = ''
        dhall-to-nix <<< "${file}" > $out
      '';

      buildInputs = [ pkgs.haskellPackages.dhall-nix ];
    };
  in
    import "${drv}";
}