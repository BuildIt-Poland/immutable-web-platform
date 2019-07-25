
{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  env-config, 
  ... 
}:
let
  namespace = env-config.kubernetes.namespace;
  istio-ns = namespace.istio;
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
  ];

  config = {
    kubernetes.helm.instances.weave-scope = {
      name = "weave-scope";
      chart = k8s-resources.weave-scope;
      namespace = "${istio-ns}";
      values = {
        global = {
          service = {
            port = 80;
            name = "weave-scope-app";
          };
        };
      };
    };
  };
}
