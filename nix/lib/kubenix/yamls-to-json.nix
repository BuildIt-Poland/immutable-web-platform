# FIXME merge with yaml to json
{lib, pkgs, ...}:
with pkgs;
{src, name, yamlsPattern, version}:
  stdenv.mkDerivation {
    inherit name version src;
    phases = ["installPhase"];
    buildInputs = [pkgs.remarshal pkgs.gawk pkgs.jq];
    installPhase = ''
      for file in $src/${yamlsPattern}
      do
        remarshal -i $file -if yaml -of json >>resources.jsonl
      done

      # convert jsonl file to json array, remove null values and write to $out
      cat resources.jsonl | jq -Scs 'walk(
        if type == "object" then
          with_entries(select(.value != null))
        elif type == "array" then
          map(select(. != null))
        else
          .
        end)' > $out
    '';
  }