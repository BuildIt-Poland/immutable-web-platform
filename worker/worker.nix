# worker shell
# IMPORTANT: nix is lazy so we can require whole ./nix folder and reuse the scripts - awesome isn't it?
{
}:
let
  pkgs = (import ./nix {}).pkgs;
  testScript = pkgs.writeScriptBin "test-script" ''
    echo '{"foo": 0}' | ${pkgs.jq}/bin/jq .
    echo "hello test script"
  '';
in
with pkgs;
mkShell {
  inputsFrom = [
  ];

  buildInputs = [
    # secrets
    sops
    jq
    testScript
  ];

  PROJECT_NAME = env-config.projectName;
  VERSION = env-config.version;

  # known issue: when starting clean cluster expose-brigade is run to early
  shellHook= ''
    echo "hey hey hey worker"
  '';
}