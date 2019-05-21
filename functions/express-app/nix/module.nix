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

  kubernetes.api.service.express-app = {
    spec = {
      replicas = 1;
      selector.matchLabels.app = "express-example-app";
      template = {
        containers.express-app = {
          image = config.docker.images.express-app.path;
          imagePullPolicy = "IfNotPresent";
          env = {
            TARGET = "Node.js Sample v1";
          };
        };
      };
    };
  };

  kubernetes.api.namespaces."${namespace}" = {};

  kubernetes.helm.instances.brigade = {
    namespace = "${namespace}";
    chart = charts.mongodb-chart;
  };
}