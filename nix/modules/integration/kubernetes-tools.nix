{config, pkgs, kubenix, k8s-resources, lib, inputs, ...}:
let
  cfg = config;
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
  };

  config = 
    mkIf cfg.kubernetes.enabled (mkMerge [
      { checks = ["Enabling kubernetes tools module"]; }

      (mkIf cfg.kubernetes.tools.enable 
      {
        packages = with pkgs; [
          istioctl
          knative

          kube-prompt
          hey
          kail
          kubectx

          kubectl
          popeye
          debug
          krew
          dig
        ];

        shellHook = 
          let
            plugins = [
              "get-all" 
              "who-can" 
              "outdated"
            ];
            plugin-install = name: "${pkgs.kubectl}/bin/kubectl krew install ${name}";
            commands = lib.concatStringsSep "\n" (builtins.map plugin-install plugins);
          in 
          ''
            ${pkgs.lib.log.message "Installing kubectl plugins"}

            ${pkgs.kubectl}/bin/kubectl krew update
            ${commands}
          '';
        })
    ]);
}