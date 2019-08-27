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

    # ARGO password:  https://github.com/argoproj/argo-cd/issues/829
    kubernetes.patches = [
      (pkgs.writeScriptBin "patch-argo-password" ''
        ${pkgs.lib.log.important "Patching Argo CD admin password"}

        pass=${"$\{1:-admin}"}
        ${pkgs.kubectl}/bin/kubectl patch secret -n ${argo-ns} argocd-secret \
          -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" $pass | tr -d ':\n')'"}}'
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
