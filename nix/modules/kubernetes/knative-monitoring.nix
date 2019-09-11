# INFO: this is a bit tricky piece since it override some tightly coupled things
# goal is to add all grafana dashboard and extra datasource with prometheus
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
  knative-monitoring-ns = namespace.knative-monitoring.name;

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
      make-dashboard = file: dir: mapper: {
        "${file}" = {
          metadata = {
            name = "${file}";
            namespace = "${knative-monitoring-ns}";
            labels.grafana_dashboard = "1";
          };
          data."${file}" = mapper (builtins.readFile "${dir}/${file}");
        };
      };

      get-dashboards-from-folder = folder: mapper:
        lib.foldl (lib.mergeAttrs) {}
          (builtins.map 
            (x: make-dashboard x folder mapper) 
            (builtins.attrNames (builtins.readDir folder)));

      istio-dashboards-folder = "${k8s-resources.istio-src}/install/kubernetes/helm/istio/charts/grafana/dashboards";

      override-datasource-if-exists = panel:
        if builtins.hasAttr("datasource") panel 
          then (panel // { datasource = "prometheus-istio"; })
          else panel;

      datasource-mapper = file:
        let
          dashboard = builtins.fromJSON file;
          # make this more fancy with fold
          altered = dashboard // ({
            panels = builtins.map override-datasource-if-exists dashboard.panels;
            templating.list = builtins.map override-datasource-if-exists dashboard.templating.list;
          });
        in
          builtins.toJSON altered;

      istio-dashboards = get-dashboards-from-folder istio-dashboards-folder datasource-mapper;
      ceph-dashboards = get-dashboards-from-folder ./grafana datasource-mapper;
    in
      istio-dashboards // ceph-dashboards // {
        grafana-datasource = {
          metadata = {
            name = "grafana-istio-datasource";  
            namespace = knative-monitoring-ns;
            labels.grafana_datasource = "1";
          };
          # FIXME map istio datasource to prometheus-istio instead of Prometheus
          data."datasource.yaml" = ''
            apiVersion: 1
            datasources:
            - name: prometheus-istio
              access: proxy
              type: prometheus
              org_id: 1
              url: http://prometheus.istio-system.svc.cluster.local:9090
          '';
        };
      };
  };
}