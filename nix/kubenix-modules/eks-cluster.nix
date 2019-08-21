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
  rook-ceph-ns = namespace.rook-ceph;
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
    
    # don't like it
    # patch-efs-provisioner =
    #   let
    #     tf-output-name = "efs_provisoner";
    #     provisioner-name = "efs-provisoner";
    #   in
    #   pkgs.writeScriptBin "patch-efs-provisioner" ''
    #     echo "patching provisioner"
    #     fs_id="$(terraform output ${tf-output-name})"
    #     ${pkgs.kubectl}/bin/kubectl patch deployment ${provisioner-name} \
    #       -n ${system-ns} \
    #       -p '{"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"${provisioner-name}"}],"$setElementOrder/volumes":[{"name":"pv-volume"}],"containers":[{"$setElementOrder/env":[{"name":"AWS_REGION"},{"name":"FILE_SYSTEM_ID"},{"name":"PROVISIONER_NAME"}],"env":[{"name":"FILE_SYSTEM_ID","value":"'"$fs_id"'"}],"name":"efs-provisioner"}],"volumes":[{"$retainKeys":["name","nfs"],"name":"pv-volume","nfs":{"server":"'"$fs_id"'".efs.${project-config.aws.region}.amazonaws.com"}}]}}}}'
    #   '';
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
    # patch-efs-provisioner 
  ];

  kubernetes.api.namespaces."${system-ns}"= {};
  kubernetes.api.namespaces."${rook-ceph-ns}"= {};

  # if something is not working well here then most likely SG on AWS -> opened port for NFS
  # kubernetes.helm.instances.efs-provisioner = {
  #   namespace = system-ns;
  #   chart = k8s-resources.efs-provisioner;
  #   values = {
  #     efsProvisioner = {
  #       efsFileSystemId = project-config.eks-cluster.configuration.efs;
  #       awsRegion = project-config.aws.region;
  #       provisionerName = "kubernetes.io/aws-efs";
  #       path = "/pv";
  #       storageClass = {
  #         name = "efs";
  #         isDefault = false;
  #       };
  #     };
  #   };
  # };

  kubernetes.helm.instances.rook-ceph = {
    # namespace = rook-ceph-ns;
    namespace = system-ns;
    chart = k8s-resources.rook-ceph;
  };

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
