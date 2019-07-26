
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
in
# TODO add enabled true/false
{
  imports = with kubenix.modules; [ 
    k8s
    helm
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
        reclaimPolicy = "Retain";
        provisioner = "kubernetes.io/host-path";
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
        reclaimPolicy = "Retain";
        provisioner = "kubernetes.io/host-path";
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
    kubernetes.helm.instances.brigade-project = project-template {
      project-name = "embracing-nix-docker-k8s-helm-knative";
      pipeline-file = ../../pipeline/infrastructure.ts; # think about these long paths
      clone-url = project-config.project.repositories.code-repository;
    };

    # kubernetes.helm.instances.brigade-project = 
    # let
    #   cfg = config.docker.images;
    #   extension = cfg.brigade-extension;
    #   worker = cfg.brigade-worker;
    # in
    # {
    #   namespace = "${brigade-ns}";
    #   name = "brigade-project";
    #   chart = k8s-resources.brigade-project;
    #   values = {
    #     project = project-config.brigade.project-name;
    #     repository = project-config.brigade.project-name; # repository.location is too long # TODO check if it would work with gateway now ...
    #     # repository = project-config.repository.location;
    #     cloneURL = project-config.project.repositories.code-repository;
    #     vcsSidecar = "brigadecore/git-sidecar:latest";
    #     sharedSecret = project-config.brigade.secret-key;
    #     defaultScript = builtins.readFile project-config.brigade.pipeline; 
    #     sshKey = bitbucket.ssh-keys.priv;
    #     workerCommand = "yarn build-start";
    #     worker = {
    #       registry = cfg.docker.registry.url;
    #       name = extension.name;
    #       tag = extension.tag;
    #       # actually should be never but it seems that they are applying to this policy to sidecar as well
    #       pullPolicy = "IfNotPresent"; 
    #     };
    #     kubernetes = {
    #       cacheStorageClass = "cache-storage";
    #       buildStorageClass = "build-storage";
    #     };
    #     secrets = {
    #       awsAccessKey = aws.access-key-id;
    #       awsSecretKey = aws.secret-access-key;
    #       gitToken = bitbucket.ssh-keys.priv;
    #       gitUser = project-config.project.author-email;
    #       awsRegion = aws.region;
    #       sopsSecrets = builtins.readFile project-config.git-secrets.location;
    #       cacheBucket = aws.s3-buckets.worker-cache;
    #       workerDockerImage = worker.path;
    #     };
    #   };
    # };
  };
}
