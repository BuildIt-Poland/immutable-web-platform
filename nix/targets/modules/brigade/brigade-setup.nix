{config, pkgs, lib, kubenix, integration-modules, inputs, ...}: 
with pkgs.lib;
let
in
{
  imports = with integration-modules.modules; [
    brigade
  ];

  config = {
    brigade = {
      enabled = true;
      secret-key = inputs.brigade.secret;
      projects = 
      let
        create-project = name: file: {
          project-name = name;
          pipeline-file = file;
          project-ref = "digitalrigbitbucketteam/${name}"; # like repo
          clone-url = config.project.repositories.code-repository;
          ssh-key = config.bitbucket.ssh-keys.priv;
          # https://github.com/brigadecore/k8s-resources/blob/master/k8s-resources/brigade-project/values.yaml
          overridings = {
            kubernetes = {
              cacheStorageClass = "cache-storage";
              buildStorageClass = "build-storage";
            };
          };
        };
      in
      {
        brigade-project = create-project 
          "embracing-nix-docker-k8s-helm-knative" 
          ../../pipeline/resources-sync/pipeline.ts; 

        brigade-exec-storage-test = create-project 
          "exec-storage-test" 
          ../../pipeline/storage-test/pipeline.ts; 
      };
    };

    kubernetes = {
      namespace = {
        argo.name = "gitops";
        brigade.name = "ci";
      };
    };
  };
}