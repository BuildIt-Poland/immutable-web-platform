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
          spec = {
            containers = [{
              image = 
                if env-config.is-dev 
                  then fn-config.image-name-for-knative-service-when-dev
                  else config.docker.images.express-app.path;

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