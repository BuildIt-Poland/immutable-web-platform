{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.bitbucket = mkOption {
    default = rec {
      enabled = true;

  # ssh-keys = {
  #   bitbucket = 
  #   if builtins.pathExists ~/.ssh/bitbucket_webhook
  #     then {
  #       pub = builtins.readFile toString ~/.ssh/bitbucket_webhook.pub;
  #       priv = builtins.readFile ~/.ssh/bitbucket_webhook;
  #     } else {
  #       pub = "";
  #       priv = "";
  #     };
  # };

    };
  };

  config = mkIf cfg.bitbucket.enabled (mkMerge [
    ({
      packages = with pkgs; [
      ];
    })
  ]);
}