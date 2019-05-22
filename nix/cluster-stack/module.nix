{config, env-config, pkgs, kubenix, callPackage, ...}: 
let
  charts = callPackage ./charts.nix {};
  namespace = env-config.helm.namespace;
in
{
  imports = with kubenix.modules; [ helm k8s ];

  kubernetes.api.namespaces."${namespace}"= {};
  kubernetes.api.namespaces."istio-system"= {};
  kubernetes.api.namespaces."dupa-szatana"= {};

  kubernetes.helm.instances.brigade = {
    namespace = "${namespace}";
    chart = charts.brigade;
    # values = {
    # };
  };

  # kubernetes.api."networking.istio.io"."v1alpha3" = {
  #   Gateway."bookinfo-gateway" = {
  #     spec = {
  #       selector.istio = "ingressgateway";
  #       servers = [{
  #         port = {
  #           number = 80;
  #           name = "http";
  #           protocol = "HTTP";
  #         };
  #         hosts = ["*"];
  #       }];
  #     };
  #   };
  # };

  # kubernetes.customResources = [
  #   {
  #   group = "caching.internal.knative.dev";
  #   version = "v1alpha1";
  #   kind = "Image";
  #   description = "";
  #   module = {};# definitions."";
  # }
  #   {
  #   group = "networking.istio.io";
  #   version = "v1alpha2";
  #   kind = "kubernetes";
  #   description = "";
  #   module = {};# definitions."";
  # }
  #   {
  #   group = "config.istio.io";
  #   version = "v1alpha2";
  #   kind = "kubernetes";
  #   description = "";
  #   module = {};# definitions."";
  # }
  #   {
  #   group = "config.istio.io";
  #   version = "v1alpha2";
  #   kind = "rule";
  #   description = "";
  #   module = {};# definitions."";
  # }
  #   {
  #   group = "config.istio.io";
  #   version = "v1alpha2";
  #   kind = "handler";
  #   description = "";
  #   module = {};# definitions."";
  # }
  #   {
  #   group = "authentication.istio.io";
  #   version = "v1alpha1";
  #   kind = "MeshPolicy";
  #   description = "";
  #   module = {};# definitions."";
  # }
  #   {
  #   group = "config.istio.io";
  #   version = "v1alpha2";
  #   kind = "attributemanifest";
  #   description = "";
  #   module = {};# definitions."";
  # }
  # ];

  # Overridings
  # kubernetes.api."caching.internal.knative.dev"."v1alpha1" = {
  # };

  # kubernetes.helm.instances.istio = {
  #   namespace = "istio-system";
  #   chart = charts.istio-chart;
  # };

  # kubernetes.helm.instances.istio-init = {
  #   namespace = "istio-system";
  #   chart = charts.istio-init;
  # };

  # kubernetes.helm.instances.knative = {
  #   namespace = "${namespace}";
  #   chart = charts.knative-chart;
  # };
}