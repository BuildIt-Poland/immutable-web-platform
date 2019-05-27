# https://github.com/knative/serving/blob/master/docs/spec/overview.md#revision
# https://github.com/knative/serving/blob/master/docs/spec/spec.md 
{ kubenix, ... }:
{
  imports = with kubenix.modules; [ 
    k8s 
  ];

  kubernetes.customResources = [
    {
      group = "serving.knative.dev";
      version = "v1alpha1";
      kind = "Service";
      description = "";
      # module = definitions."service";
      resource = "knative-serve-service";
    }
  ];
} 