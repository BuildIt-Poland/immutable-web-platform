# https://github.com/knative/serving/blob/master/docs/spec/overview.md#revision
# https://github.com/knative/serving/blob/master/docs/spec/spec.md 
# https://github.com/knative/docs/blob/master/docs/serving/using-a-tls-cert.md
# https://github.com/knative/docs/blob/master/docs/serving/using-auto-tls.md
{ 
  config, 
  env-config, 
  kubenix, 
  ... 
}:
let
  namespace = env-config.kubernetes.namespace;
  functions-ns = namespace.functions;
  knative-monitoring-ns = namespace.knative-monitoring;
in
{
  imports = with kubenix.modules; [ 
    k8s 
  ];

  config = {
    kubernetes.api.namespaces."${functions-ns}"= {
      metadata = {
        labels = {
          "istio-injection" = "enabled";
        };
      };
    };

    kubernetes.customResources = [
      {
        group = "serving.knative.dev";
        version = "v1alpha1";
        kind = "Service";
        description = "";
        resource = "knative-serve-service";
      }
    ];
  };
} 