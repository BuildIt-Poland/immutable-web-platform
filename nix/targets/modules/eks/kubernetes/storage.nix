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
    ./cert-manager.nix
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
        # kube2aim
        image.tag = "v1.1.0";
        podAnnotations = config.kubernetes.annotations.iam.backups;
        credentials.useSecret = false;
        # cleanUpCRDs = true;
        snapshotsEnabled = true;
        configuration = {
          # backupSyncPeriod = project-config.storage.backup.syncPeriod;
          resticTimeout = "6h";
          provider = "aws";
          backupStorageLocation = {
            name = "aws";
            bucket = project-config.storage.backup.bucket;
            config.region = project-config.aws.region;
          };
          volumeSnapshotLocation = {
            name = "aws";
            config.region = project-config.aws.region;
          };
        };
        metrics.enabled = true;
        # metrics.serviceMonitor.enabled = true;
        schedules = project-config.storage.backup.schedules;
        deployRestic = true;
        # eks -> /var/lib/kubelet/pods -> default is correct
        # restic.podVolumePath = project-config.storage.dataDirHostPath; # this is wrong
        restic.privileged = true;
      };
    };

    kubernetes.api.storageclasses = 
      {
        build-storage = {
          metadata = {
            name = "build-storage";
          };
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-storage";
            clusterNamespace= cfg.storage.namespace;
          };
        };

        cache-storage = {
          metadata = {
            name = "cache-storage";
          };
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-cache";
            clusterNamespace= cfg.storage.namespace;
          };
        };
      };

    kubernetes.customResources = [
     (create-cr "Backup")
     (create-cr "Schedule")
     (create-cr "VolumeSnapshotLocation")
     (create-cr "BackupStorageLocation")
    ];
  };
}