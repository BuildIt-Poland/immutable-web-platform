
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
let
  cfg = config;

  customization = project-config.brigade.customization;
  brigade-extension = customization.extension;
  remote-worker = customization.remote-worker;

  namespace = project-config.kubernetes.namespace;

  brigade-ns = namespace.brigade;
  system-ns = namespace.system;

  project-template = pkgs.callPackage ./template/brigade-project.nix {
    inherit config;
  };

  helm-charts = {
    brigade-bitbucket-gateway = {
      namespace = "${brigade-ns}";
      name = "extension";
      chart = k8s-resources.brigade-bitbucket;
      values = {
        rbac = {
          enabled = true;
        };
        bitbucket = {
          service = {
            name = "service";
            type = "NodePort";
          };
        };
      };
    };

    brigade = {
      namespace = "${brigade-ns}";
      chart = k8s-resources.brigade;
    };
  } // (builtins.mapAttrs (_: project-template) project-config.brigade.projects);
in
# TODO add enabled true/false
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    helm
    docker
    docker-registry
  ];

  config = {
    docker.images.brigade-worker.image = remote-worker.docker-image;
    docker.images.brigade-extension.image = brigade-extension.docker-image;

    kubernetes.api.namespaces."${brigade-ns}"= {};

    kubernetes.helm.instances = helm-charts;

    kubernetes.patches = 
      let
        projects = builtins.attrValues project-config.brigade.projects;
        get-secret = project: pkgs.writeScript "get-secret-${project}" ''
          ${pkgs.kubectl}/bin/kubectl get secrets \
            --selector release=${project} -n ${brigade-ns} \
            -o=jsonpath='{.items[?(@.type=="brigade.sh/project")].metadata.name}'
        '';
        inject-ssh-key = {project-name, ssh-key, ...}:
          (pkgs.writeScriptBin "patch-brigade-ssh-key-for-${project-name}" ''
            ${pkgs.lib.log.important "Patching Brigade project to pass ssh-key"}

            secret=$(${get-secret "${project-name}"})
            value=$(echo "${ssh-key}" | base64 | tr -d '\n')

            ${pkgs.kubectl}/bin/kubectl patch \
              secret -n ${brigade-ns} $secret \
              -p '{"data": {"sshKey": "'"$value"'"}}'
          '');
      in
        [] ++ (builtins.map inject-ssh-key projects);

    kubernetes.api.clusterrolebindings = 
      let
        admin = "brigade-admin-privileges";
      in
      {
        "${admin}" = {
          metadata = {
            name = "${admin}";
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            name = "cluster-admin"; # TODO this is too much in case of privilages
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = "brigade-worker";
              namespace = brigade-ns;
            }
          ];
        };
      };
    # kubernetes.api.clusterrole = {};
  };
}
