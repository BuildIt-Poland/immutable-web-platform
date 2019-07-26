{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with pkgs;
with lib;
# TODO think about priorities of tasks
# sort shell hooks based on priorities and do a concat
rec {

  imports = [
    ./project-configuration.nix
    ./docker.nix 
  ];

  options.kubernetes.cluster = {
    clean = mkOption {
      default = true;
    };
  };

  options.kubernetes.enabled = mkOption {
    default = true;
  };

  options.kubernetes.tools.enabled = lib.mkOption {
    default = true;
  };

  options.kubernetes.resources.apply = lib.mkOption {
    default = true;
  };

  # imagePullPolicy = if is-dev then "Never" else "IfNotPresent";

  options.kubernetes.config = {
    version = with types; lib.mkOption {
     default = "1.13";
    };

    namespace = with types; lib.mkOption {
      defautl = {
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
          # TODO this should be local operation / remote operation
          k8s-operations.local.delete-local-cluster
        ];

        shellHook = ''
          ${log.message "Running fresh instance of local cluster"}
        '';
      })

      (mkIf cfg.kubernetes.resources.apply {
        packages = [
          k8s-operations.apply-cluster-stack
          k8s-operations.apply-functions-to-cluster
        ];

        shellHook = ''
          ${log.message "Applying resources"}
        '';
      })

      (mkIf cfg.environment.isLocal {
        packages = [
          k8s-operations.local.create-local-cluster-if-not-exists
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