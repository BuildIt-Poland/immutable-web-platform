{
  pkgs
}:
rec {
  get-path = path:
    builtins.concatStringsSep ""
      (builtins.map (x: ''["${x}"]'') path);

  extractSecret = path: pkgs.writeScript "extract-secret" ''
    echo $SECRETS | sops --input-type json -d --extract '${get-path path}' -d /dev/stdin
  '';
}