# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, env-config, pkgs, kubenix, callPackage, ...}: 
let
  express-app = callPackage ./image.nix {};
  charts = callPackage ./charts.nix {};
  fn-config = callPackage ./config.nix {};
  namespace = env-config.helm.namespace;
in
{
  imports = with kubenix.modules; [ k8s docker helm ];
  docker.images.express-app.image = express-app;

  kubernetes.api.deployments."${fn-config.label}" = {
    spec = {
      replicas = 1;
      selector.matchLabels.app = fn-config.label;
      template = {
        metadata.labels.app = fn-config.label;
        spec = {
          containers.express-app = {
            image = 
              if env-config.is-dev 
                then "${fn-config.label}:latest" 
                else config.docker.images.express-app.path;

            imagePullPolicy = fn-config.imagePolicy;
            env = fn-config.env;
            ports."${toString fn-config.port}" = {};
            resources = {
              requests = {
                cpu = fn-config.cpu;
              };
            };
          };
        };
      };
    };
  };

  kubernetes.api.services.express-app = {
    spec = {
      ports = [{
        name = "http";
        port = fn-config.port;
      }];
      selector.app = fn-config.label;
    };
  };

  kubernetes.api.namespaces."${namespace}" = {};

  kubernetes.helm.instances.mongodb = {
    namespace = "${namespace}";
    chart = charts.mongodb-chart;
  };
}