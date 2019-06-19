{stdenv, lib, pkgs}:
{src, name, version}:
  stdenv.mkDerivation {
    inherit name version src;
    phases = ["installPhase"];
    buildInputs = [pkgs.remarshal pkgs.gawk pkgs.jq];
    installPhase = ''
      awk 'BEGIN{i=1}{line[i++]=$0}END{j=1;n=0; while (j<i) {if (line[j] ~ /^---/) n++; else print line[j] >>"resource-"n".yaml"; j++}}' $src

      for file in ./resource-*.yaml
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