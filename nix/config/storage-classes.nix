{ config, pkgs, lib, kubenix, k8s-resources, project-config, ... }: 
let 
  cfg = config; 

  namespace = project-config.kubernetes.namespace;
  storage-ns = namespace.storage;
  brigade-ns = namespace.brigade;

  provisioner = project-config.storage.provisioner;
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
            namespace = brigade-ns;
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
            namespace = brigade-ns;
            name = "cache-storage";
          } // metadata;
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-cache";
            clusterNamespace= cfg.storage.namespace;
          };
        };
      };
  };
}