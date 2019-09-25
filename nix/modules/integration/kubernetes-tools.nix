{config, pkgs, kubenix, k8s-resources, lib, inputs, ...}:
let
  cfg = config;

  validate = pkgs.writeScriptBin "validate-kubernetes-resource" ''
    resource=$1
    length=$(cat $1 | yq 'length')

    for (( idx=0; idx<length; idx++ ))
    do
      cat $resource | yq '.items['"$idx"']' | ${pkgs.conftest}/bin/conftest -o tap test $* -
    done
  '';
  install-default-krew-plugins = 
    let
      plugins = [
        "get-all" 
        "who-can" 
        "outdated"
      ];
      plugin-install = name: "${pkgs.kubectl}/bin/kubectl krew install ${name}";
      commands = lib.concatStringsSep "\n" (builtins.map plugin-install plugins);
    in 
      pkgs.writeScriptBin "install-default-krew-plugins" ''
        ${pkgs.lib.log.message "Installing kubectl plugins"}

        ${pkgs.kubectl}/bin/kubectl krew update
        ${commands}
      '';
in
with lib;
{

  imports = [
    ./kubernetes.nix
  ];

  options.kubernetes = {
    tools.enable = mkOption {
      default = true;
    };
    validation.enable = mkOption {
      default = true;
    };
  };

  config = mkIf cfg.kubernetes.enabled (mkMerge [
    { checks = ["Enabling kubernetes tools module"]; }

    (mkIf cfg.kubernetes.tools.enable {
      packages = with pkgs; [
        argocd
        istioctl
        kn
        ko

        kube-prompt
        hey
        kail
        kubectx

        kubectl
        popeye
        kubectl-debug
        kubectl-krew
        kubectl-dig
        install-default-krew-plugins 
      ];

      shellHook = '' '';
    })

    (mkIf cfg.kubernetes.tools.enable {
      packages = with pkgs; [
        conftest
        validate
        opa
      ];
    })

    (mkIf cfg.kubernetes.validation.enable {
      actions.queue = [
        { priority = cfg.actions.priority.low; 

          action = 
            let
              resources = 
                builtins.mapAttrs 
                  (x: y: {name = x; to-validate = y.yaml.objects;})
                  config.modules.kubernetes;

              yamls = builtins.attrValues resources;
              validate-resource = file: ''
                ${pkgs.lib.log.message "OPA validation for: ${file.name}"}
                ${validate}/bin/${validate.name} ${file.to-validate} -p $PWD/policy/kubernetes
              '';
              commands = lib.concatStringsSep "\n" (builtins.map validate-resource yamls);
            in
            ''
              ${pkgs.lib.log.info "Running kubernetes resources validation"}
              ${commands}
            '';
        }
      ];
    })
  ]);
}