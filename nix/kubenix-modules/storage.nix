# IN PROGRESS
{ 
  config, 
  lib, 
  kubenix, 
  pkgs,
  k8s-resources,
  project-config, 
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  rook-ceph-ns = namespace.storage;

  create-cr = kind: resource: {
    inherit kind resource;

    group = "ceph.rook.io";
    version = "v1";
    description = "";
  };
in
with lib;
with kubenix.lib.helm;
{
  imports = with kubenix.modules; [ 
    k8s
    helm
    k8s-extension
  ];

  options.storage = {
    provisioner = mkOption {
      default = "ceph.rook.io/block";
    };
    blockPools = mkOption {
      # TODO add type {name: spec (replicated.size)}
      default = {};
    };
    namespace = mkOption {
      default = rook-ceph-ns;
    };

    toolbox = {
      enable = mkOption {
        default = true;
      };
    };
  };

  config = {
    kubernetes.api.namespaces."${rook-ceph-ns}"= {};

    kubernetes.helm.instances.rook-ceph = {
      namespace = rook-ceph-ns;
      chart = k8s-resources.rook-ceph;
    };

    kubernetes.api.storage-block-pools = 
      let
        mkPool = name: value: {
          metadata = ({
            inherit name;
            namespace = rook-ceph-ns;
          });
          spec = (lib.recursiveUpdate {
            replicated.size = 3;
          } value);
        };
        pools = builtins.mapAttrs mkPool config.storage.blockPools;
      in
        pools;

    kubernetes.api.storage-cluster = {
      file-store = {
        metadata = {
          name = "rook-ceph";
          namespace = rook-ceph-ns;
        };

        spec = {
          # For the latest ceph images, see https://hub.docker.com/r/ceph/ceph/tags
          cephVersion.image = "ceph/ceph:v14.2";
          dataDirHostPath = "/var/lib/rook";
          mon = {
            allowMultiplePerNode = true;
            count = 2;
          };
          dashboard = {
            enabled = true;
            port = 8443;
            ssl = false;
          };
          storage = {
            useAllNodes = true;
            useAllDevices = false;
            # Important: Directories should only be used in pre-production environments
            directories = [
              { path =  "/var/lib/rook";}
            ];
            config = {
              storeType = "filestore";
              # mgr:
              #   nodeAffinity:
              #   tolerations:
              # mon:
              #   nodeAffinity:
              #   tolerations:
              # osd:
              #   nodeAffinity:
              #   tolerations:
            };
          };
        };
      };
    };

    kubernetes.crd = [
    ];

    # TODO should be handled similary to helm - don't need to have another pattern here
    kubernetes.static = [
      (override-static-yaml 
        { metadata.namespace = rook-ceph-ns; }
        k8s-resources.rook-ceph-toolbox)
    ];

    kubernetes.customResources = [
      (create-cr "CephBlockPool" "storage-block-pools")
      (create-cr "CephCluster" "storage-cluster")
    ];
  };
}