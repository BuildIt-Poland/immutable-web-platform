{ 
  config, 
  lib, 
  kubenix, 
  charts,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  istio-ns = namespace.istio;
  knative-monitoring-ns = namespace.knative-monitoring;
  argo-ns = namespace.argo;
  brigade-ns = namespace.brigade;
  system-ns = namespace.system;
  storage-ns = namespace.storage;
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
  # TODO should be gateways
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
      type = "LoadBalancer";
      ports = [
        # OPS
        {
          port = 15400;
          targetPort = 15400;
          nodePort = 31350;
          name = "rook-ceph-port";
        } 
        # Monitoring
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
        # Deployments
        {
          port = 15200;
          targetPort = 15200;
          nodePort = 31200;
          name = "argocd-port";
        } 
        # CI/CD
        {
          port = 15201;
          targetPort = 15201;
          nodePort = 31201;
          name = "kashti-port";
        } 
      ];
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
          } {
            port = {
              number = 15201;
              name = "http-kashti";
              protocol = "HTTP";
            };
            hosts = ["*"];
          } {
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
          } {
            port = {
              number = 15400;
              name = "http2-rook-ceph";
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

      VirtualService.cluster-services = 
      let
        make-route = host: port: {
          destination = {
            inherit host;
            port.number = port;
          };
        };

        match-http = gateway-port: host: port: {
          match = [ { port = gateway-port; } ];
          route = [ (make-route host port) ];
        };

        match-tls = gateway-port: host: port: {
          match = [{ 
            port = gateway-port; 
            sni_hosts = [ "*" ];
          }];
          route = [ (make-route host port) ];
        };
      in
      {
        metadata = {
          name = "virtual-service";
        };

        spec = {
          hosts = [ "*" ];
          gateways = ["virtual-services-gateway"];

          tls = [
            (match-tls 15200 "argocd-server.${argo-ns}.svc.cluster.local" 443)
            (match-tls 15400 "rook-ceph-mgr-dashboard.${storage-ns}.svc.cluster.local" 8443)
          ];

          http = [
            (match-http 15300 "grafana.${knative-monitoring-ns}.svc.cluster.local" 30802)
            (match-http 15301 "weave-scope-app.${istio-ns}.svc.cluster.local" 80)
            (match-http 15302 "zipkin.${istio-ns}.svc.cluster.local" 9411)
            (match-http 15201 "brigade-kashti.${brigade-ns}.svc.cluster.local" 80)
          ];
        };
      };
    };
  };
} 