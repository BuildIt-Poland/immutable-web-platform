{
  config, 
  env-config, 
  pkgs, 
  kubenix, 
  callPackage, 
  ...
}: 
let
  remote-worker = callPackage ./image.nix {};
in
{
  imports = with kubenix.modules; [ helm k8s docker ];

  docker.images.remote-worker.image = remote-worker;

  kubernetes.api.deployments."remote-worker" = {
    spec = {
      replicas = 1;
      selector.matchLabels.app = "remote-worker";
      template = {
        metadata.labels.app = "remote-worker";
        spec = {
          # TODO
          # https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
          # securityContext.fsGroup = 1000;

          containers."remote-worker" = {
            image = config.docker.images.remote-worker.path;
            imagePullPolicy = "Never";
            ports."5000" = {};
            command = [ "nix-serve" ];
            env = [{
              name = "NIX_STORE_DIR";
              value = "/global-store";
            }];
            volumeMounts."/global-store".name = "build-storage";
          };
          # BUG: it would mount when there will be first build
          volumes."build-storage" = {
            persistentVolumeClaim = {
              claimName = "embracing-nix-docker-k8s-helm-knative-test";
            };
          };
        };
      };
    };
  };

  kubernetes.api.services.remote-worker = {
    spec = {
      ports = [{
        name = "http";
        port = 5000;
      }];
      selector.app = "remote-worker";
    };
  };
}
