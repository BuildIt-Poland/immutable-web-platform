{ 
  pkgs,
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
with kubenix.lib.helm;
let
  namespace = project-config.kubernetes.namespace;
  knative-monitoring-ns = namespace.knative-monitoring;

  override-namespace = 
      override-static-yaml 
        { metadata.namespace = knative-monitoring-ns; };

  # FIXME move me to kubenix-lib/override
  override = 
    resource: 
    mapper: 
      pkgs.writeText "overrided-json"
        (builtins.toJSON 
          (builtins.filter (v: v != null) 
          (builtins.map mapper (builtins.fromJSON (builtins.readFile resource)))));
in
{
  imports = with kubenix.modules; [ 
    k8s-extension
  ];

  config = {
    kubernetes.api.namespaces."${knative-monitoring-ns}"= {};

    kubernetes.static = [
      # FIXME make me easier to follow
      # INFO as there is custom grafana helm chart - there needs to be provided some alternation to knative-monitoring
      (override k8s-resources.knative-monitoring-json (v: 
          if (v.kind == "Deployment" && v.metadata.name == "grafana") then null
          else if (lib.hasPrefix "grafana-dashboard" v.metadata.name) then 
            (lib.recursiveUpdate v { metadata.labels.grafana_dashboard = "1"; })
          else if (lib.hasPrefix "grafana-datasources" v.metadata.name) then 
            (lib.recursiveUpdate v { metadata.labels.grafana_datasource = "1"; })
          else v
      ))
    ];

    module.scripts = [
      (pkgs.writeScriptBin "get-grafana-admin-password" ''
        ${pkgs.kubectl}/bin/kubectl -n ${knative-monitoring-ns} get secret grafana \
          -o jsonpath="{.data.admin-password}" | base64 --decode && echo
      '')
    ];

    # INFO need to have separate instance to be able to add dashboards dynamicaly 
    kubernetes.helm.instances.grafana = {
      namespace = "${knative-monitoring-ns}";
      chart = k8s-resources.grafana;
      values = {
        sidecar.dashboards.enabled = true;
        sidecar.datasources.enabled = true;
      };
    };

    kubernetes.api.configmaps = 
    let
      make-dashboard = file: dir: {
        "${file}" = {
          metadata = {
            name = "${file}";
            namespace = "${knative-monitoring-ns}";
            labels.grafana_dashboard = "1";
          };
          data."${file}" = builtins.readFile "${dir}/${file}";
        };
      };

      get-dashboards-from-folder = folder:
        lib.foldl (lib.mergeAttrs) {}
          (builtins.map 
            (x: make-dashboard x folder) 
            (builtins.attrNames (builtins.readDir folder)));

      istio-src = pkgs.fetchFromGitHub {
        owner = "istio";
        repo = "istio";
        rev = "a0b1b397d9637a3308e0373d6df9ac3b5974a790";
        sha256 = "1mdfsgp03x1bv55zzpsqjlzvnyamgpy70z8vwy17wpa04v74l7qc";
      };
      istio-dashboards-folder = "${istio-src}/install/kubernetes/helm/istio/charts/grafana/dashboards";

      istio-dashboards = get-dashboards-from-folder istio-dashboards-folder;
      ceph-dashboards = get-dashboards-from-folder ./grafana;
    in
      istio-dashboards // ceph-dashboards // {
        grafana-datasource = {
          metadata = {
            name = "grafana-datasources";  
            namespace = "${knative-monitoring-ns}";
            labels.grafana_datasource = "1";
          };
          # FIXME there could be a clash betweet knative & istio (Prometheus vs prometheus)
          data."datasource.yaml" = ''
            apiVersion: 1
            datasources:
            - name: Prometheus
              access: proxy
              type: prometheus
              org_id: 1
              url: http://prometheus.istio-system.svc.cluster.local:9090
          '';
        };
      };
  };
}