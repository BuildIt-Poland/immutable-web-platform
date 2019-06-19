# when trying to convert istio, some templates include tab-s
# and it is causing that remarshal is not able to parse such file
{
  pkgs,
  lib,
  stdenvNoCC
}:
let 
chart2json = {
  # chart to template
  chart

  # release name
, name

  # namespace to install release into
, namespace ? null

  # values to pass to chart
, values ? {}

  # kubernetes version to template chart for
, kubeVersion ? null }: let
  valuesJsonFile = builtins.toFile "${name}-values.json" (builtins.toJSON values);
in stdenvNoCC.mkDerivation {
  name = "${name}.json";
  buildCommand = ''
    # template helm file and write resources to yaml
    helm template --name "${name}" \
      ${lib.optionalString (kubeVersion != null) "--kube-version ${kubeVersion}"} \
      ${lib.optionalString (namespace != null) "--namespace ${namespace}"} \
      ${lib.optionalString (values != {}) "-f ${valuesJsonFile}"} \
      ${chart} > resources.yaml
    awk 'BEGIN{i=1}{line[i++]=$0}END{j=1;n=0; while (j<i) {if (line[j] ~ /^---/) n++; else print line[j] >>"resource-"n".yaml"; j++}}' resources.yaml

    for file in ./resource-*.yaml
    do
      (cat $file | tr -d "\t") | (remarshal -if yaml -of json >>resources.jsonl)
    done

    cat resources.jsonl | jq -Scs 'walk(
      if type == "object" then
        with_entries(select(.value != null))
      elif type == "array" then
        map(select(. != null))
      else
        .
      end)' > $out
  '';
  nativeBuildInputs = [ pkgs.kubernetes-helm pkgs.gawk pkgs.remarshal pkgs.jq ];
};