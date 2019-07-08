
{ 
  config, 
  lib, 
  kubenix, 
  charts,
  env-config, 
  brigade-extension,
  remote-worker,
  ... 
}:
let
  namespace = env-config.kubernetes.namespace;

  local-infra-ns = namespace.infra;
  brigade-ns = namespace.brigade;
  istio-ns = namespace.istio;
  functions-ns = namespace.functions;
  knative-monitoring-ns = namespace.knative-monitoring;

  ssh-keys = env-config.ssh-keys;
  aws-credentials = env-config.aws-credentials;
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
      chart = charts.brigade;
    };

    kubernetes.helm.instances.brigade-bitbucket-gateway = {
      namespace = "${brigade-ns}";
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

    # https://github.com/brigadecore/charts/blob/master/charts/brigade-project/values.yaml
    kubernetes.helm.instances.brigade-project = 
    let
      cfg = config.docker.images;
      extension = cfg.brigade-extension;
      worker = cfg.brigade-worker;
    in
    {
      namespace = "${brigade-ns}";
      name = "brigade-project";
      chart = charts.brigade-project;
      values = {
        project = env-config.brigade.project-name;
        repository = env-config.brigade.project-name; # repository.location is too long # TODO check if it would work with gateway now ...
        # repository = env-config.repository.location;
        cloneURL = env-config.repository.git;
        vcsSidecar = "brigadecore/git-sidecar:latest";
        sharedSecret = env-config.brigade.sharedSecret;
        defaultScript = builtins.readFile env-config.brigade.pipeline; 
        sshKey = ssh-keys.bitbucket.priv;
        workerCommand = "yarn build-start";
        worker = {
          registry = env-config.docker.registry;
          name = extension.name;
          tag = extension.tag;
          # actually should be never but it seems that they are applying to this policy to sidecar as well
          pullPolicy = "IfNotPresent"; 
        };
        kubernetes = {
          cacheStorageClass = "cache-storage";
          buildStorageClass = "build-storage";
        };
        secrets = {
          awsAccessKey = aws-credentials.aws_access_key_id;
          awsSecretKey = aws-credentials.aws_secret_access_key;
          awsRegion = aws-credentials.region;
          sopsSecrets = builtins.readFile env-config.secrets;
          cacheBucket = env-config.s3.worker-cache;
          workerDockerImage = worker.path;
        };
      };
    };
  };
}
