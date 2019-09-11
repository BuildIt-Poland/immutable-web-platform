
{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  istio-ns = namespace.istio.name;
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
