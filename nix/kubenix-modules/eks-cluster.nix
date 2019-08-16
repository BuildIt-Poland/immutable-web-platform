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
  kn-serving = namespace.knative-serving;

  update-eks-vpc-cni = 
    pkgs.writeScriptBin "apply-aws-credentails-secret" ''
      ${pkgs.lib.log.important "Patching AWS VPC CNI"}

      ${pkgs.kubectl}/bin/kubectl patch daemonset aws-node \
        -n kube-system \
        -p '{"spec": {"template": {"spec": {"containers": [{"image": "602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni:v1.5.1-rc1","name":"aws-node"}]}}}}'
    '';

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
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    helm
  ];

  kubernetes.patches = [
    update-eks-vpc-cni
    knative-not-resolve-tags
  ];

  kubernetes.api.namespaces."${system-ns}"= {};

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md
  kubernetes.helm.instances.eks-cluster-autoscaler = {
    namespace = "${system-ns}";
    chart = k8s-resources.cluster-autoscaler;
    values ={
      rbac.create = "true";
      cloudProvider = "aws";
      sslCertPath =  "/etc/ssl/certs/ca-bundle.crt"; # it is necessary in case of EKS
      awsRegion = project-config.aws.region;
      autoDiscovery = {
        clusterName = "${project-config.kubernetes.cluster.name}";
        enabled = true;
      };
      nodeSelector = {
        "kubernetes.io/lifecycle"= "on-demand";
      };
    };
  };

  # TODO helm install stable/k8s-spot-termination-handler
}
