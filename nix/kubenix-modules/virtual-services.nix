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

  match-tls = name: host: port: {
    match = [{ 
      port = 443;
      sniHosts = [ (mk-domain name) ];
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
    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."virtual-services-gateway" = 
      let
        hosts  = [
          (mk-domain "monitoring")
          (mk-domain "topology")
          (mk-domain "storage")
          (mk-domain "gitops")
          (mk-domain "tracing")
          (mk-domain "ci")
        ];
      in
      {
        # BUG: this metadata should be taken from name
        metadata = {
          name = "virtual-services-gateway";
          namespace = istio-ns;
          annotations = {
            type = "external";
          };
        };
        spec = {
          selector.istio = "ingressgateway";
          servers = [
            {
            inherit hosts;

            port = {
              number = 80;
              name = "http-system";
              protocol = "HTTP";
            };
          } 
          {
            inherit hosts;

            port = {
              number = 443;
              name = "https-system";
              protocol = "HTTPS";
            };
            tls = {
              mode = "SIMPLE";
              privateKey = "sds";
              serverCertificate = "sds";
              credentialName = "ingress-cert"; # FROM EKS-module
            };
          }];
        };
      };

      VirtualService.grafana = {
        metadata = {
          name = "monitoring-services";
          namespace = istio-ns;
        };
        spec = {
          hosts = [ (mk-domain "monitoring") ];
          gateways = ["virtual-services-gateway"];
          http = [
            (match-http "grafana.${knative-monitoring-ns}.svc.cluster.local" 30802)
          ];
          tls = [
            (match-tls "monitoring" "grafana.${knative-monitoring-ns}.svc.cluster.local" 30802)
          ];
        };
      };

      VirtualService.topology = {
        metadata = {
          name = "topology-services";
          namespace = istio-ns;
        };
        spec = {
          hosts = [ (mk-domain "topology") ];
          gateways = ["virtual-services-gateway"];
          http = [
            (match-http "weave-scope-app.${istio-ns}.svc.cluster.local" 80)
          ];
          tls = [
            (match-tls "topology" "weave-scope-app.${istio-ns}.svc.cluster.local" 80)
          ];
        };
      };

      VirtualService.gitops = {
        metadata = {
          name = "gitops-services";
          namespace = istio-ns;
        };
        spec = {
          hosts = [ (mk-domain "gitops") ];
          gateways = ["virtual-services-gateway"];
          http = [
            (match-http "argocd-server.${argo-ns}.svc.cluster.local" 443)
          ];
          tls = [
            (match-tls "gitops" "argocd-server.${argo-ns}.svc.cluster.local" 443)
          ];
        };
      };

      VirtualService.storage = {
        metadata = {
          name = "storage-services";
          namespace = istio-ns;
        };
        spec = {
          hosts = [ (mk-domain "storage") ];
          gateways = ["virtual-services-gateway"];
          http = [
            (match-http "rook-ceph-mgr-dashboard.${storage-ns}.svc.cluster.local" 8443)
          ];
          tls = [
            (match-tls "storage" "rook-ceph-mgr-dashboard.${storage-ns}.svc.cluster.local" 8443)
          ];
        };
      };

      #       (match-http 15302 "zipkin.${istio-ns}.svc.cluster.local" 9411)
      #       (match-http 15201 "brigade-kashti.${brigade-ns}.svc.cluster.local" 80)
    };
  };
}