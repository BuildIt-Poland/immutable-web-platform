# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, lib, project-config, pkgs, kubenix, ...}: 
let
  express-app = pkgs.callPackage ./image.nix {};
  fn-config = pkgs.callPackage ./config.nix {};
  package = pkgs.callPackage ./package.nix {};
  tests = import ./test { inherit pkgs; };

  namespaces= project-config.kubernetes.namespace;
in
{
  imports = with kubenix.modules; [ 
    k8s 
    docker-registry
    knative-serve
    k8s-extension
  ];

  module.packages = {
    express-app = package;
  };

  module.tests = tests;

  docker.images.express-app.image = express-app;

  kubernetes.api."knative-serve-service" = {
    "${fn-config.label}" = {
      metadata = {
        name = fn-config.label;
        namespace = namespaces.functions;
      };
      spec = {
        template = {
          metadata = {
            # app = project-config.projectName;
            # https://github.com/knative/docs/blob/master/docs/serving/samples/autoscale-go/README.md
            annotations = {
              "autoscaling.knative.dev/class" = "kpa.autoscaling.knative.dev";
              "autoscaling.knative.dev/metric" = "concurrency";
              "autoscaling.knative.dev/target" = "5";
              "autoscaling.knative.dev/maxScale" = "100";
            };
          };
          spec = {
            containers = [{
              image = config.docker.images.express-app.path;

              imagePullPolicy = project-config.kubernetes.imagePullPolicy;
              env = fn-config.env;
              livenessProbe = {
                httpGet = {
                  path = "/healthz";
                };
                initialDelaySeconds = 3;
                periodSeconds = 3;
              };
              resources = {
                requests = {
                  cpu = fn-config.cpu;
                };
              };
            }];
          };
        };
      };
    };
  };

  # https://github.com/knative/docs/blob/master/docs/serving/using-a-custom-domain.md#apply-from-a-file
  kubernetes.api.configmaps = {
    knative-domain = {
      metadata = {
        name = "config-domain";
        namespace = "knative-serving";
      };
      data = {
        "dev.cluster" = "";
      };
    };
  };
}