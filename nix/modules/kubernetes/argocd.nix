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
    k8s-extension
    helm
  ];

  config = {
    kubernetes.api.namespaces."${argo-ns}"= {};

    module.scripts = [
      (pkgs.writeShellScriptBin "get-argo-cd-password" ''
        ${pkgs.kubectl}/bin/kubectl -n ${argo-ns} get secret argocd-secret \
          -o 'go-template={{index .data "admin.password"}}' \
        | base64 --decode && echo
      '')
    ];

    kubernetes.helm.instances.argo-cd = {
      namespace = "${argo-ns}";
      chart = k8s-resources.argo-cd;
      values = {
        server = {
          serviceAnnotations = {
            "certmanager.k8s.io/cluster-issuer" = "cert-issuer";
          };
        };
      };
    };
  };
}
