{config, pkgs, lib, kubenix, integration-modules, ...}: 
let
  resources = config.kubernetes.resources;
  priority = resources.priority;
  minikube-operations = pkgs.callPackage ./minikube-operations.nix {};
in
with lib;
{
  imports = with integration-modules.modules; [
    ./docker-image-push.nix
    project-configuration
    kubernetes
    skaffold
    docker
  ];

  config = mkMerge [
    ({
      docker = rec {
        namespace = "${config.project.name}";
        registry = mkForce "";
        imageName = mkForce (name: "${config.environment.type}.${config.project.domain}/${name}");
        imageTag = mkForce (name: "${config.docker.tag}");
      };

      packages = with pkgs; [
        minikube
      ];

      project = rec {
        domain = mkForce "local";
      };

      kubernetes.resources.list."${priority.high "istio"}" = [ kubenix.modules.istio-service-mesh ];
      # INFO: this is an example how to can test module locally first - eks is not enabled yet
      kubernetes.resources.list."${priority.high "policy"}" = [ kubenix.modules.opa ];

      skaffold.enable = true;
    })

    (mkIf config.kubernetes.cluster.clean {
      packages = with minikube-operations; [
        delete-local-cluster
        create-local-cluster-if-not-exists
      ];

      actions.queue = [
        { priority = config.actions.priority.cluster; 
          action = ''
            delete-local-cluster
          '';
        }
        { priority = config.actions.priority.cluster; 
          action = ''
            create-local-cluster-if-not-exists
          '';
        }
      ];
    })

    ({
      packages = [
        minikube-operations.skaffold-build
        minikube-operations.setup-env-vars
      ];
      actions.queue = [
        { priority = config.actions.priority.docker + 1; # INFO before uploading docker images
          action = ''
            source setup-env-vars
          '';
        }
      ];
    })

    ({
      packages = with minikube-operations;[
        expose-brigade-gateway
        create-localtunnel-for-brigade
      ];

      help = [
        "-- Brigade integration --"
        "To expose brigade gateway for BitBucket events, run '${minikube-operations.expose-brigade-gateway.name}'"
        "To make gateway accessible from outside, run '${minikube-operations.create-localtunnel-for-brigade.name}'"
      ];
    })
  ];
}