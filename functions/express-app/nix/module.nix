# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, lib, project-config, pkgs, kubenix, ...}: 
let
  express-app = pkgs.callPackage ./image.nix {};
  fn-config = pkgs.callPackage ./config.nix {};
  package = pkgs.callPackage ./package.nix {};

  tests = import ./test { 
    inherit pkgs; 
    docker = express-app;
  };

  # TODO move call-function 
  scripts = import ./scripts { inherit pkgs; };

  namespaces= project-config.kubernetes.namespace;
  functions-ns = namespaces.functions.name;

  # FIXME ingress port for isio - instead of 31380
  # FIXME for hosted cluster it is not necessary
  call-function = 
    (pkgs.writeScriptBin "call-express-app-function-minikube" ''
      ${pkgs.curl}/bin/curl \
        '-sS' \
        '-H' 'Host: ${fn-config.label}.${functions-ns}.${fn-config.domain}' \
        '-H' 'User: ${project-config.project.authorEmail}' \
        http://$(${pkgs.minikube}/bin/minikube ip -p ${project-config.project.name}):31380 -v
    '');
in
{
  imports = with kubenix.modules; [ 
    k8s 
    docker-registry
    knative-serve
    k8s-extension
    tekton-crd
  ];

  module.packages = {
    express-app = package;
  };

  module.tests = tests;

  module.scripts = [
    call-function
  ];

  docker.images.express-app.image = express-app;

  kubernetes.imports = [
    ./pipeline/task-run.yaml
    ./pipeline/task.yaml
  ];

  kubernetes.api."knative-serve-service" = {
    "${fn-config.label}" = {
      metadata = {
        name = fn-config.label;
        namespace = functions-ns;
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
}