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
    namespace = "${namespace}";
    chart = charts.brigade;
    # values = {
    # };
  };

  # INFO json cannot be applied here as it is handled via helm module

  kubernetes.helm.instances.brigade-bitbucket-gateway = {
    namespace = "${namespace}";
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

  kubernetes.helm.instances.brigade-project = {
    namespace = "${namespace}";
    name = "brigade-project";
    chart = charts.brigade-project;
    values = {
      project = "digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative";
      repository = "bitbucket.org/digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative";
      cloneURL = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
      vcsSidecar = "brigadecore/git-sidecar:latest";
      sharedSecret = env-config.brigade.sharedSecret;
      sshKey = ''
        -----BEGIN RSA PRIVATE KEY-----
        -----END RSA PRIVATE KEY-----
        '';
    };
  };
}