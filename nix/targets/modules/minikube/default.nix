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

      packages = with pkgs; with minikube-operations; [
        minikube
        quick-bootstrap
        delete-local-cluster
        create-local-cluster
        kube-psp-advisor
      ];

      environment = {
        vars = {
          KO_DOCKER_REPO = "ko.local";
        };
      };

      project = rec {
        domain = mkForce "local";
      };

      kubernetes = {
        tools.enable = true;
        resources.list."${priority.high "istio"}" = [ ./service-mesh.nix ];
        resources.list."${priority.high "storage"}" = [ ./storage.nix ];
      };

      skaffold.enable = true;
    })

    (mkIf config.kubernetes.cluster.clean {
      packages = with minikube-operations; [
        delete-local-cluster
        create-local-cluster
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
      # use minikube tunel
      packages = with minikube-operations;[
        # expose-brigade-gateway
        create-localtunnel
      ];

      help = [
        # "-- Brigade integration --"
        # "To expose brigade gateway for BitBucket events, run '${minikube-operations.expose-brigade-gateway.name}'"
        # "To make gateway accessible from outside, run '${minikube-operations.create-localtunnel-for-brigade.name}'"
      ];
    })
  ];
}