# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, env-config, pkgs, kubenix, callPackage, ...}: 
let
  express-app = callPackage ./image.nix {};
  charts = callPackage ./charts.nix {};
  namespace = env-config.helm.namespace;
in
{
  imports = with kubenix.modules; [ k8s docker helm ];
  docker.images.express-app.image = express-app;

  kubernetes.api.deployments.express-app = {
    spec = {
      replicas = 1;
      selector.matchLabels.app = "express-app";
      template = {
        metadata.labels.app = "express-app";
        spec = {
          containers.express-app = {
            # image = config.docker.images.express-app.path;
            image = "express-knative-example-app:latest"; # should be env flag sensitive
            imagePullPolicy = "Never"; # dev
            # imagePullPolicy = "IfNotPresent"; # prod
            env = {
              # TARGET = "Node.js Sample v1";
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
        port = 80;
      }];
      selector.app = "express-example-app";
    };
  };

  kubernetes.api.pods.express-app = {
    metadata.name = "express-app";
    metadata.labels.app = "express-app";
    spec = {
      containers.express-app = {
        image = config.docker.images.express-app.path;
        imagePullPolicy = "IfNotPresent";
        # env = {
        #   TARGET = "Node.js Sample v1";
        # };
      };
    };
  };

  kubernetes.api.namespaces."${namespace}" = {};

  kubernetes.helm.instances.mongodb = {
    namespace = "${namespace}";
    chart = charts.mongodb-chart;
  };
}