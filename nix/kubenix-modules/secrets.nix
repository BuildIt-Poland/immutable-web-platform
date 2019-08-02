
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
stringData:
  config.yaml: |-
    apiUrl: "https://my.api.com/api/v1"
    username: {{username}}
    password: {{password}}

{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources ? pkgs.k8s-resources,
  project-config,
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  argo-ns = namespace.argo;
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
  ];

  config = {
    kubernetes.api.namespaces."${argo-ns}"= {};

    # TODO
    # ARGO password:  https://github.com/argoproj/argo-cd/issues/829
    # there is a cli - a bit regret that this is not a kubernetes resource
    kubernetes.helm.instances.argo-cd = {
      namespace = "${argo-ns}";
      chart = k8s-resources.argo-cd;
    };
  };
}
