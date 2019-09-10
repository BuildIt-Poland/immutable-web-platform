# https://eksworkshop.com/scaling/deploy_hpa/
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources ? pkgs.k8s-resources,
  project-config,
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  eks-ns = "eks";
  kn-serving = namespace.knative-serving;
  istio-ns = namespace.istio;
  functions-ns = namespace.functions;

  # https://knative.dev/docs/serving/tag-resolution/
  # https://github.com/knative/serving/issues/4435#issuecomment-504108797 
  # https://github.com/knative/serving/pull/4084
  knative-not-resolve-tags =
    pkgs.writeScriptBin "knative-not-resolve-tags" ''
      ${pkgs.lib.log.important "Patching Knative serving"}

      ${pkgs.kubectl}/bin/kubectl patch configmap config-deployment \
        -n ${kn-serving} \
        -p '{"data":{"registriesSkippingTagResolving":"${project-config.aws.account}.dkr.ecr.${project-config.aws.region}.amazonaws.com/${project-config.kubernetes.cluster.name}"}}'
    '';

  setup-velero-namespace =
    pkgs.writeScriptBin "setup-velero-namespace" ''
      ${pkgs.lib.log.important "Patching Velero namespace"}

      ${pkgs.velero}/bin/velero client config set namespace=${eks-ns}
    '';
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    ./service-mesh.nix
    ./virtual-services.nix
    ./storage.nix
  ];

  kubernetes.patches = [
    knative-not-resolve-tags
    setup-velero-namespace
  ];

  kubernetes.annotations = {
    instance-on-demand = {"kubernetes.io/lifecycle"= "on-demand";};
    iam = { 
      # FIXME these should be 2 separate roles
      cluster = {"iam.amazonaws.com/allowed-roles" = "[\"${project-config.kubernetes.cluster.name}*\"]";};
      backups = {"iam.amazonaws.com/allowed-roles" = "[\"${project-config.kubernetes.cluster.name}*\"]";};
    };
  };

  kubernetes.api.namespaces."${eks-ns}"= {
    metadata.annotations = config.kubernetes.annotations.iam.cluster;
  };
 
   # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md
  kubernetes.helm.instances.eks-cluster-autoscaler = {
    namespace = "${eks-ns}";
    chart = k8s-resources.cluster-autoscaler;
    values = {
      rbac.create = "true";
      cloudProvider = "aws";
      sslCertPath =  "/etc/ssl/certs/ca-bundle.crt"; # it is necessary in case of EKS
      awsRegion = project-config.aws.region;
      autoDiscovery = {
        clusterName = "${project-config.kubernetes.cluster.name}";
        enabled = true;
      };
      nodeSelector = config.kubernetes.annotations.instance-on-demand;
    };
  };

  kubernetes.helm.instances.external-dns = {
    namespace = "${eks-ns}";
    chart = k8s-resources.external-dns;
    values = {
      provider = "aws"; 
      istioIngressGateways = [
        "istio-system/istio-ingressgateway"
      ];
      sources = ["service" "ingress" "istio-gateway"];
      rbac.create = true;
      policy = "upsert-only";
      logLevel = "debug";
      aws = {
        region = project-config.aws.region;
      };
      domainFilters = [project-config.project.domain];
    };
  };

  kubernetes.helm.instances.kube2iam = {
    namespace = "${eks-ns}";
    chart = k8s-resources.kube2iam;
    values = {
      rbac.create = true;
    };
  };

  # FIXME helm stable/k8s-spot-termination-handler
}
