# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, lib, env-config, pkgs, kubenix, callPackage, ...}: 
let
  express-app = callPackage ./image.nix {};
  charts = callPackage ./charts.nix {};
  fn-config = callPackage ./config.nix {};
  namespaces= env-config.kubernetes.namespace;
  test = env-config.knative-serve;
in
{
  imports = with kubenix.modules; [ 
    k8s 
    docker 
    # helm 
  ];

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
            # https://github.com/knative/docs/blob/master/docs/serving/samples/autoscale-go/README.md
            annotations = {
              "autoscaling.knative.dev/class" = "kpa.autoscaling.knative.dev";
              "autoscaling.knative.dev/metric" = "concurrency";
              "autoscaling.knative.dev/target" = "5";
              "autoscaling.knative.dev/maxScale" = "100";
            };
          };
          spec = {
            containers = 
            let
              image = config.docker.images.express-app;
            in
            [{
              # image = "${image.registry}/${image.name}:${image.tag}";
              image = config.docker.images.express-app.path;

              imagePullPolicy = env-config.imagePullPolicy;
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

  kubernetes.api.namespaces."${namespaces.functions}" = {};
  kubernetes.api.namespaces."${namespaces.infra}" = {};

  # TODO
  # kubernetes.helm.instances.mongodb = {
  #   namespace = "${namespaces.infra}";
  #   chart = charts.mongodb-chart;
  #   values = {
  #     usePassword = !env-config.is-dev;
  #   };
  # };
}