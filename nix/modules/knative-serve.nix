{ kubenix, ... }:
{
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