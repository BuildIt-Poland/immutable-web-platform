{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with pkgs;
with lib;
rec {

  imports = [
    ./project-configuration.nix
    ./docker.nix 
  ];

  options.kubernetes = {

    cluster = {
      clean = mkOption {
        default = true;
      };
    };

    enabled = mkOption {
      default = true;
    };

    tools.enabled = mkOption {
      default = true;
    };

    resources = {
      apply = mkOption {
        default = true;
      };
      save = mkOption {
        default = true;
      };
    };

    version = with types; mkOption {
     default = "1.13";
    };

    imagePullPolicy = mkOption {
      default = "IfNotPresent";
    };

    namespace = with types; mkOption {
      default = {
        functions = "functions";
        infra = "local-infra";
        brigade = "brigade";
        istio = "istio-system";
        knative-monitoring = "knative-monitoring";
        knative-serving = "knative-serving";
        argo = "argocd";
      };
    };
  };

  config = 
    mkIf cfg.kubernetes.enabled (mkMerge [
      ({
        packages = [
          kubectl
        ];
      })

      (mkIf cfg.kubernetes.cluster.clean {
        packages = [
          k8s-operations.local.delete-local-cluster
        ];

        actions.queue = [
          { priority = cfg.actions.priority.cluster; 
            action = ''
              delete-local-cluster
            '';
          }
        ];
      })

      (mkIf cfg.kubernetes.resources.apply {
        packages = [
          k8s-operations.apply-cluster-stack
          k8s-operations.apply-functions-to-cluster
          k8s-operations.local.create-local-cluster-if-not-exists
          k8s-operations.local.setup-env-vars
        ];

        actions.queue = [{ 
          priority = cfg.actions.priority.cluster; 
          action = ''
            create-local-cluster-if-not-exists
            source setup-env-vars
            apply-cluster-stack
          '';
        }];
      })

      (mkIf cfg.kubernetes.resources.save {
        packages = [
          k8s-operations.save-resources
        ];

        shellHook = ''
          ${log.message "Checking existence of local cluster"}
          save-resources
        '';
      })

      (mkIf (cfg.kubernetes.tools.enabled && cfg.environment.isLocal) {
        packages = with pkgs; [
          knctl
          kubectl-repl
          kubernetes-helm
          hey
          istioctl
          skaffold
          minikube
        ];
      })
    ]);
}