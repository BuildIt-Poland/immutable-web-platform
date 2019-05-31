{
  config, 
  env-config, 
  pkgs, 
  kubenix, 
  callPackage, 
  ...
}: 
let
  charts = callPackage ./charts.nix {};
  remote-worker = callPackage ./remote-worker.nix {};

  namespace = env-config.kubernetes.namespace;
  local-infra-ns = namespace.infra;
  brigade-ns = namespace.brigade;
  istio-ns = namespace.istio;
  ssh-keys = env-config.ssh-keys;
  aws-credentials = env-config.aws-credentials;
in
{
  imports = with kubenix.modules; [ helm k8s docker ];

  docker.images.remote-worker.image = remote-worker;

  kubernetes.api.namespaces."${local-infra-ns}"= {};
  kubernetes.api.namespaces."${brigade-ns}"= {};
  kubernetes.api.namespaces."${istio-ns}"= {};

  kubernetes.api.deployments."remote-worker" = {
    spec = {
      replicas = 1;
      selector.matchLabels.app = "remote-worker";
      template = {
        metadata.labels.app = "remote-worker";
        spec = {
          containers."remote-worker" = {
            image = "remote-worker:latest"; #config.docker.images.remote-worker.path;
            imagePullPolicy = "Never";
            ports."5000" = {};
            command = [ "nix-serve" ];
          };
        };
      };
    };
  };

  kubernetes.api.services.remote-worker = {
    spec = {
      ports = [{
        name = "https";
        port = 5000;
      }];
      selector.app = "remote-worker";
    };
  };

  # most likely bitbucket gateway does not handle namespace -> envvar BRIGADE_NAMESPACE
  # perhaps need to pass it somehow during creation -> invetigate
  kubernetes.helm.instances.brigade = {
    namespace = "${brigade-ns}";
    chart = charts.brigade;
    # values = {
    # };
  };

  # INFO json cannot be applied here as it is handled via helm module

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

  # https://github.com/brigadecore/charts/blob/master/charts/brigade-project/values.yaml
  kubernetes.helm.instances.brigade-project = {
    namespace = "${brigade-ns}";
    name = "brigade-project";
    chart = charts.brigade-project;
    values = {
      project = env-config.brigade.project-name;
      repository = env-config.repository.location;
      cloneURL = env-config.repository.git;
      vcsSidecar = "brigadecore/git-sidecar:latest";
      sharedSecret = env-config.brigade.sharedSecret;
      defaultScript = builtins.readFile env-config.brigade.pipeline; 
      sshKey = builtins.readFile ssh-keys.bitbucket.priv;
      secrets = {
        awsAccessKey = aws-credentials.aws_access_key_id;
        awsSecretKey = aws-credentials.aws_secret_access_key;
        awsRegion = aws-credentials.region;
        secrets = builtins.readFile env-config.secrets;
      };
    };
  };
}