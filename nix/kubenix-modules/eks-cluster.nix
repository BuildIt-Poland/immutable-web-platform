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

    # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md
    kubernetes.helm.instances.eks-cluster-autoscaler = {
      namespace = "${system-ns}";
      chart = k8s-resources.cluster-autoscaler;
      values ={
        rbac.create = "true";
        cloudProvider = "aws";
        awsRegion = project-config.aws.region;
        autoDiscovery = {
          clusterName = "${project-config.kubernetes.cluster.name}";
          enabled = true;
        };
      };
    };
  };
}
