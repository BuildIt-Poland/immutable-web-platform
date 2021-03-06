# should lives somewhere else - everything should have access to it
{
  pkgs
}:
rec {
  get-path = path:
    builtins.concatStringsSep ""
      (builtins.map (x: ''["${x}"]'') path);

  extractSecret = path: file: pkgs.writeScript "extract-secret" ''
    echo '${builtins.readFile file}' | sops --input-type json -d --extract '${get-path path}' -d /dev/stdin
  '';
}