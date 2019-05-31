# worker shell
# IMPORTANT: nix is lazy so we can require whole ./nix folder and reuse the scripts - awesome isn't it?
{
}:
let
  # pkgs = (import ../nix {}).pkgs;
  pkgs = import <nixpkgs> {};
  testScript2 = pkgs.writeScript "test-script" ''
    echo '{"foo": 0}' | ${pkgs.jq}/bin/jq .
    echo "hello test script"
  '';
  testScript = pkgs.stdenv.mkDerivation {
    name = "test-script";
    src = ./.;
    phases = ["installPhase"];
    buildInputs = [pkgs.jq];
    preferLocalBuild = true;
    installPhase = ''
      mkdir -p $out/bin
      cp ${testScript2} $out/bin/${testScript2.name}
    '';
  };
in
with pkgs; 
{ 
  inherit testScript;
  shell = mkShell {
    inputsFrom = [
    ];

    buildInputs = [
      # secrets
      sops
      jq
      testScript
    ];

    # PROJECT_NAME = env-config.projectName;
    # VERSION = env-config.version;

    # known issue: when starting clean cluster expose-brigade is run to early
    shellHook= ''
      echo "hey hey hey worker"
    '';
  };
}