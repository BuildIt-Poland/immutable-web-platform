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

    # FIXME if local
    # ARGO password:  https://github.com/argoproj/argo-cd/issues/829
    kubernetes.patches = [
      (pkgs.writeScriptBin "patch-argo-password" ''
        ${pkgs.log.info "Patching Argo CD admin password"}
        ${pkgs.kubectl}/bin/kubectl patch secret -n argocd argocd-secret \
          -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" admin | tr -d ':\n')'"}}'
      '')
    ];

    # TODO
    # there is a cli - a bit regret that this is not a kubernetes resource
    kubernetes.helm.instances.argo-cd = {
      namespace = "${argo-ns}";
      chart = k8s-resources.argo-cd;
    };
  };
}
