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
in
# TODO add enabled true/false
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
  ];

  options.kubernetes.monitoring = {
    gateway = lib.mkOption {};
  };

  config = {
    # values: https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/gateways/values.yaml
    kubernetes.monitoring.gateway = {
      enabled = true;
      labels = {
        app = "monitoring-gateway";
        istio = "monitoring-ingressgateway";
      };
      type = "NodePort";
      ports = [{
        port = 15300;
        targetPort = 15300;
        nodePort = 31300;
        name = "grafana-port";
      } {
        port = 15301;
        targetPort = 15301;
        nodePort = 31301;
        name = "weavescope-port";
      } {
        port = 15302;
        targetPort = 15302;
        nodePort = 31302;
        name = "zipkin-port";
      } ];
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
      Gateway."grafana-gateway" = {
        # BUG: this metadata should be taken from name
        metadata = {
          name = "grafana-gateway";
        };
        spec = {
          selector.istio = "monitoring-ingressgateway";
          servers = [{
            port = {
              number = 15301;
              name = "http2-weavescope";
              protocol = "HTTP2";
            };
            hosts = ["*"];
          } {
            port = {
              number = 15300;
              name = "http2-grafana";
              protocol = "HTTP2";
            };
            hosts = ["*"];
          } {
            port = {
              number = 15302;
              name = "http2-zipkin";
              protocol = "HTTP2";
            };
            hosts = ["*"];
          }];
        };
      };
      DestinationRule.grafana = {
        metadata = {
          name = "destination-rule-grafana";
        };
        spec = {
          host = "grafana.${knative-monitoring-ns}.svc.cluster.local";
          trafficPolicy.tls.mode = "DISABLE";
        };
      };
      VirtualService.grafana = {
        metadata = {
          name = "virtualservice-grafana";
        };
        spec = {
          hosts = ["*"];
          gateways = ["grafana-gateway"];
          http = [
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
          ];
        };
      };
    };
  };
} 