{ 
  config, 
  lib, 
  kubenix, 
  charts,
  env-config, 
  ... 
}:
let
  namespace = env-config.kubernetes.namespace;
  istio-ns = namespace.istio;
  knative-monitoring-ns = namespace.knative-monitoring;
  argo-ns = namespace.argo;
in
# TODO create similar module for gitops
# TODO argocd sth is not correct here - investigate
# TODO add enabled true/false
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
  ];

  options.kubernetes.virtual-services = {
    gateway = lib.mkOption {};
  };

  config = {
    # values: https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/gateways/values.yaml
    kubernetes.virtual-services.gateway = {
      enabled = true;
      # https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/gateways/values.yaml#L15
      # TODO define limits
      # sds = {
      #   enabled = true;
      #   image = "node-agent-k8s";
      #   requests = {
      #     cpu = "100m";
      #     memory = "128Mi";
      #   };
      # };
      labels = {
        app = "virtual-services";
        istio = "virtual-services-gateway";
      };
      type = "NodePort";
      ports = [
        {
        port = 15300;
        targetPort = 15300;
        nodePort = 31300;
        name = "grafana-port";
      } 
      {
        port = 15301;
        targetPort = 15301;
        nodePort = 31301;
        name = "weavescope-port";
      } {
        port = 15302;
        targetPort = 15302;
        nodePort = 31302;
        name = "zipkin-port";
      } 
      {
        port = 15200;
        targetPort = 15200;
        nodePort = 31200;
        name = "argocd-port";
      } 
      ];
    };

    kubernetes.helm.instances.weave-scope = {
      name = "weave-scope";
      chart = charts.weave-scope;
      namespace = "${istio-ns}";
      values = {
        global = {
          service = {
            port = 80;
            name = "weave-scope-app";
          };
        };
      };
    };

    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."virtual-services-gateway" = {
        # BUG: this metadata should be taken from name
        metadata = {
          name = "virtual-services-gateway";
        };
        spec = {
          selector.istio = "virtual-services-gateway";
          servers = [{
            port = {
              number = 15301;
              name = "http-weavescope";
              protocol = "HTTP";
            };
            hosts = ["*"];
          } {
            port = {
              number = 15300;
              name = "http-grafana";
              protocol = "HTTP";
            };
            hosts = ["*"];
          } {
            port = {
              number = 15302;
              name = "http-zipkin";
              protocol = "HTTP";
            };
            hosts = ["*"];
          } 
          {
            port = {
              number = 15200;
              name = "http2-argocd";
              protocol = "HTTPS";
            };
            tls = {
              mode = "PASSTHROUGH";
            };
            hosts = [ 
              "*"
            ];
          }
          ];
        };
      };
      VirtualService.cluster-services = {
        metadata = {
          name = "virtual-service";
        };
        spec = {
          hosts = [
            "*"
          ];
          gateways = ["virtual-services-gateway"];
          tls = [{
            match = [
              { 
                port = 15200; 
                sni_hosts = [
                  "localhost"
                  "kind.local"
                  "*"
                ];
              }
            ];
            route = [{
              destination = {
                host = "argocd-server.${argo-ns}.svc.cluster.local";
                port.number = 443;
              };
            }];
          }];
          http = [
          # MONITORING 15300+
          {
            match = [
              { port = 15300; }
            ];
            route = [{
              destination = {
                host = "grafana.${knative-monitoring-ns}.svc.cluster.local";
                port.number = 30802; # take this port from somewhere - create ports map
              };
            }];
          } 
          {
            match = [
              { port = 15301; }
            ];
            route = [{
              destination = {
                host = "weave-scope-app.${istio-ns}.svc.cluster.local";
                port.number = 80;
              };
            }];
          }
          {
            match = [
              { port = 15302; }
            ];
            route = [{
              destination = {
                host = "zipkin.${istio-ns}.svc.cluster.local";
                port.number = 9411; 
              };
            }];
          }
          # {
          #   match = [
          #     { port = 15200; }
          #   ];
          #   route = [{
          #     destination = {
          #       host = "argocd-server.${argo-ns}.svc.cluster.local";
          #       port.number = 443;
          #     };
          #   }];
          # }
          ];
        };
      };
    };
  };
} 