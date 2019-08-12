{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
  isLocalKubernetes = cfg.environment.isLocal && cfg.kubernetes.target == "minikube";
in
with pkgs;
with lib;
rec {

  imports = [
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

      name = mkOption {
        default = ""; 
      };
    };

    target = mkOption {
      default = "minikube";
      type = types.enum ["minikube" "eks" "aks" "gcp"];
    };

    patches = {
      run = with types; mkOption {
        default = "";
      };
      enable = mkOption {
        default = true;
        description = ''
          Kubernetes patches to be applied after resource creation
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

    namespace = with types; {
      functions = mkOption { default = "functions";};
      infra = mkOption { default = "local-infra";};
      brigade = mkOption { default = "brigade";};
      istio = mkOption { default = "istio-system";};
      knative-monitoring = mkOption { default = "knative-monitoring";};
      knative-serving = mkOption { default = "knative-serving";};
      argo = mkOption { default = "argocd";};
      system = mkOption { default = "system";};
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

      (mkIf (cfg.kubernetes.cluster.clean && isLocalKubernetes) {
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

      ({
        packages = [ 
          k8s-operations.apply-crd 
          k8s-operations.apply-resources
        ];
      })

      (mkIf cfg.kubernetes.cluster.clean {

        actions.queue = [
          { priority = cfg.actions.priority.crd; 
            action = ''
              apply-k8s-crd
            '';
          }
        ];
      })

      (mkIf cfg.kubernetes.patches.enable {
        actions.queue = [{ 
          priority = cfg.actions.priority.resources - 1; # after resources were applied
          action = ''
            ${cfg.kubernetes.patches.run}
          '';
        }];
      })

      (mkIf cfg.kubernetes.resources.apply {

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
        actions.queue = [
          { priority = cfg.actions.priority.docker + 1; # INFO before uploading docker images
            action = ''
              source setup-env-vars
            '';
          }
        ];
      })
    ]);
}