{ 
  config, 
  lib, 
  kubenix, 
  pkgs,
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  istio-ns = namespace.istio.name;
  service-mesh-config = config.kubernetes.network-mesh;

  create-istio-cr = kind: {
    inherit kind;

    group = "config.istio.io";
    version = "v1alpha2";
    description = "";
    resource = kind;
  };
in {
  imports = with kubenix.modules; [ 
    k8s
    istio
  ];

  config = {
    kubernetes.customResources = [
      (create-istio-cr "attributemanifest")
      (create-istio-cr "kubernetes")
      (create-istio-cr "rule")
      (create-istio-cr "handler")
      (create-istio-cr "instance")
    ];
  };
}