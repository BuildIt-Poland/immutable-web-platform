# from: https://knative.dev/docs/serving/samples/hello-world/helloworld-nodejs/

{config, lib, env-config, pkgs, kubenix, modules, callPackage, ...}: 
let
  express-app = callPackage ./image.nix {};
  charts = callPackage ./charts.nix {};
  fn-config = callPackage ./config.nix {};
  namespace = env-config.helm.namespace;
  test = env-config.knative-serve;
  # temp
  knative-module = import ../../../nix/modules/knative-serve.nix;
  istio2 = import ./istio.nix;
in
{
  imports = with kubenix.modules; [ 
    k8s 
    docker 
    helm 
    istio2
    knative-module
  ];
  kubernetes.api."serving.knative.dev"."v1alpha1" = {
    host = "dsadas";
  };

  kubernetes.api.istioo.gateway = {
    # "bookinfo-gateway" = {
    #   spec = {
    #     selector.istio = "ingressgateway";
    #     servers = [{
    #       port = {
    #         number = 80;
    #         name = "http";
    #         protocol = "HTTP";
    #       };
    #       hosts = ["*"];
    #     }];
    #   };
    # };
    # "bookinfo-gateway-2" = {
    #   spec = {
    #     selector.istio = "ingressgateway";
    #     servers = [{
    #       port = {
    #         number = 80;
    #         name = "http";
    #         protocol = "HTTP";
    #       };
    #       hosts = ["*"];
    #     }];
    #   };
    # };
  };

    kubernetes.api."networking.istio.io"."v1alpha3" = {
    Gateway."bookinfo-gateway" = {
      spec = {
        selector.istio = "ingressgateway";
        servers = [{
          port = {
            number = 80;
            name = "http";
            protocol = "HTTP";
          };
          hosts = ["*"];
        }];
      };
    };
    };

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

  kubernetes.api.knative = {
    host = "testset";
  };

  # knative.api.services = env-config;
  # knative.api.services.express-app = {
  #   apiVersion = "serving.knative.dev/v1alpha1";
  #   spec = {
  #     template = {
  #       metadata.labels.app = fn-config.label;
  #       spec = {
  #         containers.express-app = {
  #           image = 
  #             if env-config.is-dev 
  #               then "${fn-config.label}:latest" 
  #               else config.docker.images.express-app.path;

  #           imagePullPolicy = fn-config.imagePolicy;
  #           env = fn-config.env;
  #           ports."${toString fn-config.port}" = {};
  #           resources = {
  #             requests = {
  #               cpu = fn-config.cpu;
  #             };
  #           };
  #         };
  #       };
  #     };
  #     ports = [{
  #       name = "http";
  #       port = fn-config.port;
  #     }];
  #     selector.app = fn-config.label;
  #   };
  # };

  kubernetes.api.namespaces."${namespace}" = {};

  kubernetes.helm.instances.mongodb = {
    namespace = "${namespace}";
    chart = charts.mongodb-chart;
  };
}