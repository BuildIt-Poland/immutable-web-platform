{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  #     aws-profiles = super.callPackage ./lib/get-aws-credentials.nix {};
  options.aws = mkOption {
    default = rec {
    aws-credentials = {};
  #   if (env == "brigade" || !builtins.pathExists ~/.aws/credentials)
  #   then
  #     # TODO will be exported as env vars
  #     {

  #       aws_access_key_id = "";
  #       aws_secret_access_key = "";
  #       region = "";
  #     }
  #   else
  #   let
  #     aws = aws-profiles.default; # TODO add ability to change profile
  #   in
  #     if (builtins.hasAttr "region" aws)
  #       then aws
  #       else aws // { region = if region != null then region else "eu-west-2"; };
    };
  };

  config = mkIf cfg.aws.enabled (mkMerge [
    ({
      packages = with pkgs; [
        
      ];
    })
  ]);
}