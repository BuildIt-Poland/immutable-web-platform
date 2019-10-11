{ config, pkgs, lib, kubenix, k8s-resources, project-config, ... }: 
let 
  cfg = config; 

  namespace = project-config.kubernetes.namespace;
  provisioner = project-config.storage.provisioner;
in
{
  imports = with kubenix.modules; [ 
    k8s
  ];

  config = {
    kubernetes.api.storageclasses = 
      {
        build-storage = {
          metadata = {
            name = "build-storage";
          };
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-storage";
            clusterNamespace= namespace.storage.name;
          };
        };

        cache-storage = {
          metadata = {
            name = "cache-storage";
          };
          provisioner = provisioner;
          parameters = {
            blockPool = "brigade-cache";
            clusterNamespace= namespace.storage.name;
          };
        };
      };
  };
}