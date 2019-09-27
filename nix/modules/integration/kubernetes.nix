{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
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

    namespace = with types; 
    let
      mkNamespaceOption = name: {
        name = mkOption {
          default = name;
        };
        metadata = mkOption {
          default = {};
        };
      };
    in
    {
      functions = mkNamespaceOption "functions";
      infra = mkNamespaceOption "infra";
      brigade = mkNamespaceOption "brigade";
      tekton-pipelines = mkNamespaceOption "tekton-pipelines";
      istio = mkNamespaceOption "istio-system";
      knative-monitoring = mkNamespaceOption "knative-monitoring";
      knative-serving = mkNamespaceOption "knative-serving";
      knative-eventing = mkNamespaceOption "knative-eventing";
      argo = mkNamespaceOption "argocd";
      system = mkNamespaceOption "system";
      storage = mkNamespaceOption "storage";
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

    ]);
}