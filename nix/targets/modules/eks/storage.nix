{ config, pkgs, lib, kubenix, k8s-resources, project-config, ... }: 
let 
  cfg = config; 

  namespace = project-config.kubernetes.namespace;

  provisioner = project-config.storage.provisioner;

  create-cr = kind: {
    inherit kind;

    group = "velero.io";
    version = "v1";
    description = "";
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    helm
    storage
  ];

  config = {
    storage.blockPools = {
      brigade-storage = {
        replicated.size = 1;
      };
      brigade-cache = {
        replicated.size = 1;
      };
    };

    # FIXME ADD if backup enabled ...
    kubernetes.helm.instances.backup = {
      namespace = "eks";
      chart = k8s-resources.velero;
      values = {
        # https://github.com/helm/charts/blob/master/stable/velero/templates/deployment.yaml#L27
        podAnnotations = config.kubernetes.annotations.iam.backups;
        # kube2aim
        credentials.useSecret = false;
        # FIXME should not be static -> terraform
        configuration = {
          provider = "aws";
          backupStorageLocation = {
            name = "aws";
            bucket = project-config.storage.backup.bucket;
            region = project-config.aws.region;
          };
          snapshotLocationConfig = {
            region = project-config.aws.region;
          };
        };
      };
    };

    kubernetes.api.storageclasses = 
      let
        metadata = {
          annotations = {
            "storageclass.beta.kubernetes.io/is-default-class" = "false"; 
          };
          labels = {
            "addonmanager.kubernetes.io/mode" = "EnsureExists";
          };
        };
      in
      {
        build-storage = {
          metadata = {
            name = "build-storage";
          } // metadata;
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-storage";
            clusterNamespace= cfg.storage.namespace;
          };
        };

        cache-storage = {
          metadata = {
            name = "cache-storage";
          } // metadata;
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-cache";
            clusterNamespace= cfg.storage.namespace;
          };
        };
      };

    kubernetes.customResources = [
     (create-cr "Backup")
     (create-cr "VolumeSnapshotLocation")
     (create-cr "BackupStorageLocation")
    ];
  };
}