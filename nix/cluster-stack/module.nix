{config, env-config, pkgs, kubenix, callPackage, ...}: 
let
  charts = callPackage ./charts.nix {};
  namespace = env-config.kubernetes.namespace.infra;
in
{
  imports = with kubenix.modules; [ helm k8s ];

  kubernetes.api.namespaces."${namespace}"= {};
  kubernetes.api.namespaces."istio-system"= {};


  # most likely bitbucket gateway does not handle namespace -> envvar BRIGADE_NAMESPACE
  # perhaps need to pass it somehow during creation -> invetigate
  kubernetes.helm.instances.brigade = {
    # namespace = "${namespace}";
    chart = charts.brigade;
    # values = {
    # };
  };

  # INFO json cannot be applied here as it is handled via helm module
  # https://github.com/lukepatrick/brigade-bitbucket-gateway/blob/master/charts/brigade-bitbucket-gateway/values.yaml

  # TODO base64 X-Hook-UUID
  # TODO EDITOR=nvim kubectl edit roles brigade-bitbucket-gateway-brigade-bitbucket-gateway
  # kubectl get secrets
  # EDITOR=nvim kubectl edit secret <brigade-project-name>
  
  # add namespace
  # TODO rbac resource needs to be improved -> kubectl edit roles brigade-bitbucket-gateway-brigade-bitbucket-gateway -n local-infra
  # and has access to pods
  # rules:
  # - apiGroups:
  #   - ""
  #   resources:
  #   - pods
  # . - secrets
  #   verbs:
  #   - '*'
  # - apiGroups:
  #   - extensions
  #   - apps
  #   resources:
  #   - deployments
  #   - replicasets
  #   verbs:
  #   - '*'
  kubernetes.helm.instances.brigade-bitbucket-gateway = {
    # namespace = "${namespace}";
    name = "brigade-bitbucket-gateway";
    chart = charts.brigade-bitbucket;
    values = {
      rbac = {
        enabled = true;
      };
      bitbucket = {
        name = "brigade-bitbucket-gateway";
        service = {
          name = "service";
          type = "NodePort";
        };
      };
    };
  };
}