# IN PROGRESS
{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  rook-ceph-ns = namespace.rook-ceph;
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  options.storage = {
    provisioner = mkOption {
      default = "ceph.rook.io/block";
    };
    blockPool = mkOption {
      default = "";
    };
  };

  # Block pool
  # apiVersion: ceph.rook.io/v1
  # kind: CephBlockPool
  # metadata:
  #   name: replicapool
  #   namespace: system
  # spec:
  #   replicated:
  #     size: 3

  config = {
    kubernetes.helm.instances.rook-ceph = {
      namespace = rook-ceph-ns;
      chart = k8s-resources.rook-ceph;
    };

    kubernetes.api.namespaces."${rook-ceph-ns}"= {
    };

    kubernetes.crd = [
    ];

    kubernetes.static = [
    ];

    kubernetes.customResources = [
    ];
  };
}