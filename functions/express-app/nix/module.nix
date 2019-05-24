# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, lib, env-config, pkgs, kubenix, modules, callPackage, ...}: 
let
  express-app = callPackage ./image.nix {};
  charts = callPackage ./charts.nix {};
  fn-config = callPackage ./config.nix {};
  namespace = env-config.helm.namespace;
  test = env-config.knative-serve;
  # temp
  # knative-module = import modules.knative-module;
  knative-module = import ../../../nix/modules/knative-serve.nix;
in
{
  imports = with kubenix.modules; [ 
    k8s 
    docker 
    helm 
    # modules.knative-serve
    knative-module
  ];

  docker.images.express-app.image = express-app;

  kubernetes.api."knative-serve-service" = {
    "test" = {
      metadata = {
        name = "express-test-app";
        namespace = "default";
        resourceVersion = "10";#config.docker.images.express-app.path;
      };
      spec = {
        # traffic = [{
        #   revisionName = "express-test-app";
        #   # https://github.com/knative/serving/blob/6e58358927c4d111b2f39ae1e7c22a8b8cd459aa/config/config-controller.yaml#L28
        #   tag = "dev.local";
        #   percent = 100;
        # }];
        template = {
          spec = {
            containers = [{
              image = 
                if env-config.is-dev 
                  then "dev.local/${fn-config.label}:latest" 
                  else config.docker.images.express-app.path;

              imagePullPolicy = fn-config.imagePolicy;
              env = fn-config.env;
              # ports."${toString fn-config.port}" = {};
              # resources = {
              #   requests = {
              #     cpu = fn-config.cpu;
              #   };
              # };
            }];
            };
        };
      };
    };
  };

  kubernetes.api.namespaces."${namespace}" = {};

  kubernetes.helm.instances.mongodb = {
    namespace = "${namespace}";
    chart = charts.mongodb-chart;
  };
}