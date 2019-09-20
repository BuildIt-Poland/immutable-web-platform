# https://github.com/knative/serving/blob/master/docs/spec/overview.md#revision
# https://github.com/knative/serving/blob/master/docs/spec/spec.md 
# https://github.com/knative/docs/blob/master/docs/serving/using-a-tls-cert.md
# https://github.com/knative/docs/blob/master/docs/serving/using-auto-tls.md
{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
with kubenix.lib.helm;
let
  namespace = project-config.kubernetes.namespace;
  tekton-ns = namespace.tekton-pipelines;
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    tekton-crd
  ];

  config = {
    # kubernetes.api.namespaces."${tekton-ns.name}"= {
    #   metadata = lib.recursiveUpdate {} tekton-ns.metadata;
    # };

    kubernetes.static = [
      k8s-resources.tekton-pipelines-json
      k8s-resources.tekton-dashboard-json
    ];
  };
}