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
        # other location? /etc/kubernetes/pki/ca.crt -> https://medium.com/@alejandro.millan.frias/cluster-autoscaler-in-amazon-eks-d9f787176519
        sslCertPath =  "/etc/ssl/certs/ca-bundle.crt"; # it is necessary in case of EKS
        awsRegion = project-config.aws.region;
        autoDiscovery = {
          clusterName = "${project-config.kubernetes.cluster.name}";
          enabled = true;
        };
      };
    };
  };
}
