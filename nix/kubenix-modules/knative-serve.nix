# https://github.com/knative/serving/blob/master/docs/spec/overview.md#revision
# https://github.com/knative/serving/blob/master/docs/spec/spec.md 

{ kubenix, ... }:
{
  imports = with kubenix.modules; [ 
    k8s 
  ];

  # https://github.com/knative/docs/blob/master/docs/serving/using-a-custom-domain.md#apply-from-a-file
  kubernetes.api.configmaps = {
    knative-domain = {
      metadata = {
        name = "config-domain";
        namespace = "knative-serving";
      };
      data = {
        "dev.cluster" = "";
      };
    };
  };

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