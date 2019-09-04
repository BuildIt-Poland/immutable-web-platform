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

  mk-domain = name: project-config.project.make-sub-domain "${name}.services";

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

  create-virtual-service = name: svc: port: {
    metadata = {
      name = "${name}-services";
      namespace = istio-ns;
    };
    spec = {
      hosts = [ (mk-domain "${name}") ];
      gateways = ["virtual-services-gateway"];
      http = [ (match-http svc port) ];
      tls = [ (match-tls "${name}" svc port) ];
    };
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    istio
  ];

  config = {
    # values: https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/gateways/values.yaml
    kubernetes.api."networking.istio.io"."v1alpha3" = {
      Gateway."virtual-services-gateway" = 
      let
        hosts  = [
          (mk-domain "monitoring")
          (mk-domain "ci")
          (mk-domain "storage")
          (mk-domain "topology")
          (mk-domain "tracing")
          (mk-domain "bitbucket-gateway")
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

            tls.httpsRedirect = true;
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
              credentialName = "ingress-cert";
            };
          }
          {
            hosts = [(mk-domain "gitops")];

            port = {
              number = 443;
              name = "https-gitops-system";
              protocol = "HTTPS";
            };
            tls = {
              mode = "PASSTHROUGH";
            };
          }
          ];
        };
      };

      VirtualService.grafana = 
        create-virtual-service 
          "monitoring" 
          "grafana.${knative-monitoring-ns}.svc.cluster.local"
          30802;

      VirtualService.topology = 
        create-virtual-service 
          "topology" 
          "weave-scope-app.${istio-ns}.svc.cluster.local"
          80;
      
      # passthrough
      VirtualService.gitops =
        create-virtual-service 
          "gitops" 
          "argocd-server.${argo-ns}.svc.cluster.local"
          443;

      VirtualService.storage =
        create-virtual-service 
          "storage" 
          "rook-ceph-mgr-dashboard.${storage-ns}.svc.cluster.local"
          8443;

      VirtualService.tracing =
        create-virtual-service 
          "tracing" 
          "zipkin.${istio-ns}.svc.cluster.local"
          9411;

      VirtualService.ci =
        create-virtual-service 
          "ci" 
          "brigade-kashti.${brigade-ns}.svc.cluster.local" 
          80;

      # VirtualService.metrics =
      #   create-virtual-service 
      #     "metrics" 
      #     "prometheus-operated.${storage-ns}.svc.cluster.local" 
      #     9090;

      VirtualService.brigade-gateway = 
        create-virtual-service 
          "bitbucket-gateway" 
          "extension-brigade-bitbucket-gateway.${brigade-ns}.svc.cluster.local" 
          7748;
    };
  };
}