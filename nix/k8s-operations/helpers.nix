{pkgs, lib}:
with pkgs;
with lib;
{
  get-port = {
    service,
    type ? "nodePort",
    index ? 0,
    port ? "",
    namespace
  }: pkgs.writeScript "get-port" ''
    ${pkgs.kubectl}/bin/kubectl get svc ${service} \
      --namespace ${namespace} \
      --output 'jsonpath={.spec.ports[${if port != "" then "?(@.port==${port})" else toString index}].${type}}'
  '';

  port-forward = 
    let
      # INFO to filter out grep from ps
      getGrepPhrase = phrase:
        let
          phraseLength = builtins.stringLength phrase;
          grepPhrase = "[${builtins.substring 0 1 phrase}]";
          grepPhraseRest = builtins.substring 1 phraseLength phrase;
        in
          "${grepPhrase}${grepPhraseRest}";
    in
    {
      from,
      to,
      namespace,
      resourceType ? "service",
      service
    }: 
    pkgs.writeScript "port-forward-${namespace}-${service}" ''
      ${log.message "Forwarding ports $(${from}):$(${to}) for ${service}"}

      ps | grep "${getGrepPhrase service}" \
        || ${pkgs.kubectl}/bin/kubectl \
            port-forward ${resourceType}/${service} \
            --namespace ${namespace} \
            $(${toString to}):$(${toString from}) > /dev/null &
    '';

  kubectl-apply = resources: writeScript "apply-resources" ''
    ${log.info "Applying resources ${resources}"}
    cat ${resources} | ${pkgs.kubectl}/bin/kubectl apply --record -f -
  '';

  wait-for = {
    service,
    namespace ? "",
    extraArgs ? "",
    selector ? "",
    condition ? "condition=Ready",
    resource ? "pod",
    timeout ? 300,
  }:
    pkgs.writeScript "wait-for-${namespace}-${service}" ''
      ${log.message "Waiting for ${namespace}/${service}"}

      ${pkgs.kubectl}/bin/kubectl wait \
        --for=${condition} ${resource} \
        --timeout=${toString timeout}s \
        ${if namespace != "" then "--namespace '${namespace}'" else ""} \
        ${extraArgs} \
        ${if selector != "" then "--selector '${selector}'" else ""}
  '';
}