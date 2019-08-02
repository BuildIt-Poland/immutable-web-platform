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
        description = ''
          Whether should start clean cluster
          ability to override by --arg kubernetes '{clean= false;}'
        '';
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
      { checks = ["Enabling kubernetes module"]; }
      ({
        packages = [
          kubectl
        ];
      })

      (mkIf (cfg.kubernetes.cluster.clean && cfg.environment.isLocal) {
        packages = with k8s-operations.local; [
          delete-local-cluster
          create-local-cluster-if-not-exists
        ];

        actions.queue = [
          { priority = cfg.actions.priority.cluster; 
            action = ''
              delete-local-cluster
            '';
          }
          { priority = cfg.actions.priority.cluster; 
            action = ''
              create-local-cluster-if-not-exists
            '';
          }
        ];
      })

      (mkIf cfg.kubernetes.cluster.clean {
        packages = [ k8s-operations.apply-crd ];

        actions.queue = [
          { priority = cfg.actions.priority.crd; 
            action = ''
              apply-k8s-crd
            '';
          }
        ];
      })

      (mkIf cfg.kubernetes.resources.apply {
        packages = [ k8s-operations.apply-resources ];

        actions.queue = [{ 
          priority = cfg.actions.priority.resources; 
          action = ''
            apply-k8s-resources
          '';
        }];
      })

      (mkIf cfg.kubernetes.resources.save {
        packages = [
          k8s-operations.save-resources
        ];

        shellHook = ''
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
          kail
          kubectx
          k8s-operations.local.skaffold-build
          k8s-operations.local.setup-env-vars
        ];
        shellHook = ''
          source setup-env-vars
        '';
      })
    ]);
}