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
  infra-ns = namespace.infra;
  knative-ns = namespace.knative-serving;

  create-cr = kind: {
    inherit kind;

    group = "sources.nachocano.org";
    version = "v1alpha1";
    description = "";
    resource = lib.toLower kind;
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  config = {
    kubernetes.customResources = [
      (create-cr "BitBucketSource")
    ];
  };
}