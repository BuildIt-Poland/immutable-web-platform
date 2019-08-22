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
  functions-ns = namespace.functions;
  knative-ns = namespace.knative-serving;

  override-namespace = 
      override-static-yaml 
        { metadata.namespace = knative-ns; };
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  config = {
    # INFO skipping custom ns as it is a bit more complicated to put knative in separate namespace
    # kubernetes.api.namespaces."${knative-ns}"= {};

    kubernetes.api.namespaces."${functions-ns}"= {
      metadata = {
        labels = {
          "istio-injection" = "enabled";
        };
      };
    };

    kubernetes.crd = [
      k8s-resources.knative-crd-json
    ];

    kubernetes.static = [
      k8s-resources.knative-serving-json
    ];
  };
}