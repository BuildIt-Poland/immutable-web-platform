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
  system-ns = namespace.system;
in
{
  imports = with kubenix.modules; [ 
    k8s
    helm
  ];

  config = {
    kubernetes.api.namespaces."${system-ns}"= {};

    kubernetes.helm.instances.eks-cluster-autoscaler = {
      namespace = "${system-ns}";
      chart = k8s-resources.cluster-autoscaler;
      values ={
        rbac.create = "true";
        cloudProvider = "aws";
        awsRegion = project-config.aws.region;
        autoDiscovery = {
          # TODO sync with terraform: cluster_name = "${local.env-vars.project_name}-${local.env-vars.env}"
          clusterName = "${project-config.project.name}-${project-config.environment.type}";
          enabled = true;
        };
      };
    };
  };
}
