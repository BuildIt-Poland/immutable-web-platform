
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
let
  cfg = config;

  customization = project-config.brigade.customization;
  brigade-extension = customization.extension;
  remote-worker = customization.remote-worker;

  namespace = project-config.kubernetes.namespace;

  brigade-ns = namespace.brigade;

  project-template = pkgs.callPackage ./template/brigade-project.nix {
    inherit config;
  };

  sc-provisioner = 
    if project-config.environment.isLocal
      then "k8s.io/minikube-hostpath"
      else "kubernetes.io/host-path";
in
# TODO add enabled true/false
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    docker
  ];

  config = {
    docker.images.brigade-worker.image = remote-worker.docker-image;
    docker.images.brigade-extension.image = brigade-extension.docker-image;

    kubernetes.api.namespaces."${brigade-ns}"= {};

    kubernetes.helm.instances.brigade = {
      namespace = "${brigade-ns}";
      chart = k8s-resources.brigade;
    };

    kubernetes.helm.instances.brigade-bitbucket-gateway = {
      namespace = "${brigade-ns}";
      name = "brigade-bitbucket-gateway";
      chart = k8s-resources.brigade-bitbucket;
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

    kubernetes.api.storageclasses = {
      build-storage = {
        metadata = {
          namespace = brigade-ns;
          name = "build-storage";
          annotations = {
            "storageclass.beta.kubernetes.io/is-default-class" = "false"; 
          };
          labels = {
            "addonmanager.kubernetes.io/mode" = "EnsureExists";
            # exec
          };
        };
        # reclaimPolicy = "Retain";
        provisioner = sc-provisioner;
      };

      cache-storage = {
        metadata = {
          namespace = brigade-ns;
          name = "cache-storage";
          annotations = {
            "storageclass.beta.kubernetes.io/is-default-class" = "false"; 
          };
          labels = {
            "addonmanager.kubernetes.io/mode" = "EnsureExists";
          };
        };
        # reclaimPolicy = "Retain";
        provisioner = sc-provisioner;
      };
    };
    
    kubernetes.api.clusterrolebindings = 
      let
        admin = "brigade-admin-privileges";
      in
      {
        "${admin}" = {
          metadata = {
            name = "${admin}";
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            name = "cluster-admin"; # TODO this is too much in case of privilages
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = "brigade-worker";
              namespace = brigade-ns;
            }
          ];
        };
      };
    # kubernetes.api.clusterrole = {};

    # https://github.com/brigadecore/k8s-resources/blob/master/k8s-resources/brigade-project/values.yaml
    # FIXME take from project-config
    kubernetes.helm.instances.brigade-project = project-template {
      # FIXME add some ns here
      project-name = "embracing-nix-docker-k8s-helm-knative";
      pipeline-file = ../../pipeline/infrastructure.ts; # think about these long paths
      clone-url = project-config.project.repositories.code-repository;
    };
  };
}
