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

  mk-domain = project-config.project.make-sub-domain;

  make-route = host: port: {
    destination = {
      inherit host;
      port.number = port;
    };
  };

  match-http = host: port: {
    # match = [ { uri.prefix = "/"; } ];
    route = [ (make-route host port) ];
  };

  match-tls = gateway-port: name: host: port: {
    match = [{ 
      port = gateway-port; 
      sni_hosts = [ (mk-domain name) ];
    }];
    route = [ (make-route host port) ];
  };
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
    # kubernetes.virtual-services.gateway = {
    #   enabled = true;
    #   # https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/gateways/values.yaml#L15
    #   # TODO define limits
    #   # sds = {
    #   #   enabled = true;
    #   #   image = "node-agent-k8s";
    #   #   requests = {
    #   #     cpu = "100m";
    #   #     memory = "128Mi";
    #   #   };
    #   # };
    #   labels = {
    #     app = "virtual-services";
    #     istio = "virtual-services-gateway";
    #   };
    #   type = "LoadBalancer";
    #   ports = [
    #     # OPS
    #     {
    #       port = 15400;
    #       targetPort = 15400;
    #       nodePort = 31350;
    #       name = "rook-ceph-port";
    #     } 
    #     # Monitoring
    #     # {
    #     #   port = 15300;
    #     #   targetPort = 15300;
    #     #   nodePort = 31300;
    #     #   name = "grafana-port";
    #     # } 
    #     # {
    #     #   port = 15301;
    #     #   targetPort = 15301;
    #     #   nodePort = 31301;
    #     #   name = "weavescope-port";
    #     # } {
    #     #   port = 15302;
    #     #   targetPort = 15302;
    #     #   nodePort = 31302;
    #     #   name = "zipkin-port";
    #     # } 
    #     # # Deployments
    #     # {
    #     #   port = 15200;
    #     #   targetPort = 15200;
    #     #   nodePort = 31200;
    #     #   name = "argocd-port";
    #     # } 
    #     # # CI/CD
    #     # {
    #     #   port = 15201;
    #     #   targetPort = 15201;
    #     #   nodePort = 31201;
    #     #   name = "kashti-port";
    #     # } 
    #   ];
    # };

    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."virtual-services-gateway" = 
      {
        # BUG: this metadata should be taken from name
        metadata = {
          name = "virtual-services-gateway";
          annotations = {
            type = "external";
          };
        };
        spec = {
          selector.istio = "ingressgateway";
          servers = [{
            port = {
              number = 80;
              name = "http-system";
              protocol = "HTTP";
            };
            hosts = [
              (mk-domain "monitoring")
              (mk-domain "topology")
            ];
          } {
            port = {
              number = 443;
              name = "https-system";
              protocol = "HTTPS";
            };
            hosts = [
              (mk-domain "monitoring")
              (mk-domain "topology")
            ];
            tls = {
              mode = "SIMPLE";
              privateKey = "sds";
              serverCertificate = "sds";
              credentialName = "ingress-cert"; # FROM EKS
            };
          }];
        };
      };
        #    {
        #     port = {
        #       number = 15300;
        #       name = "http-grafana";
        #       protocol = "HTTP";
        #     };
        #     hosts = [
        #       "monitoring.${domain}"
        #     ];
        #   } {
        #     port = {
        #       number = 15302;
        #       name = "http-zipkin";
        #       protocol = "HTTP";
        #     };
        #     inherit hosts;
        #   } {
        #     port = {
        #       number = 15201;
        #       name = "http-kashti";
        #       protocol = "HTTP";
        #     };
        #     inherit hosts;
        #   } {
        #     port = {
        #       number = 15200;
        #       name = "http2-argocd";
        #       protocol = "HTTPS";
        #     };
        #     tls = {
        #       mode = "PASSTHROUGH";
        #     };
        #     inherit hosts;
        #   } {
        #     port = {
        #       number = 15400;
        #       name = "http2-rook-ceph";
        #       protocol = "HTTPS";
        #     };
        #     tls = {
        #       mode = "PASSTHROUGH";
        #     };
        #     inherit hosts;
        #   }
        #   ];

      VirtualService.grafana = {
        metadata = {
          name = "monitoring-services";
        };
        spec = {
          hosts = [ (mk-domain "monitoring") ];
          gateways = ["virtual-services-gateway"];
          http = [
            (match-http "grafana.${knative-monitoring-ns}.svc.cluster.local" 30802)
          ];
        };
      };

      VirtualService.topology = {
        metadata = {
          name = "topology-services";
        };
        spec = {
          hosts = [ (mk-domain "topology") ];
          gateways = ["virtual-services-gateway"];
          http = [
            (match-http "weave-scope-app.${istio-ns}.svc.cluster.local" 80)
          ];
        };
      };

      # VirtualService.cluster-services = {
      #   metadata = {
      #     name = "virtual-service";
      #   };
      #   spec = {
      #     hosts = [ "*.${domain}" ]; # temp
      #     gateways = ["virtual-services-gateway"];

      #     tls = [
      #       (match-tls 15200 "gitops" "argocd-server.${argo-ns}.svc.cluster.local" 443)
      #       (match-tls 15201 "storage" "rook-ceph-mgr-dashboard.${storage-ns}.svc.cluster.local" 8443)
      #     ];

      #     http = [
      #       # (match-http 15300 "grafana.${knative-monitoring-ns}.svc.cluster.local" 30802)
      #       # (match-http 15301 "weave-scope-app.${istio-ns}.svc.cluster.local" 80)
      #       (match-http 15302 "zipkin.${istio-ns}.svc.cluster.local" 9411)
      #       (match-http 15201 "brigade-kashti.${brigade-ns}.svc.cluster.local" 80)
      #     ];
      #   };
      # };
    };
  };
}