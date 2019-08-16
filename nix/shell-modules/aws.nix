{config, pkgs, lib, inputs, ...}:
let
  cfg = config;

  credentials-location = cfg.aws.location.credentials;
  config-location = cfg.aws.location.config;

  credentials-exists = builtins.pathExists credentials-location;
  config-exists = builtins.pathExists config-location;
in
with lib;
rec {

  imports = [
    ./project-configuration.nix
  ];

  options.aws = {
    enabled = mkOption {
      default = true;
    };

    s3-buckets = {
      worker-cache = mkOption {
        default = true;
      };
    };

    location = {
      credentials = mkOption {
        default = ~/.aws/credentials;
        type = types.path;
      };
      config = mkOption {
        default = ~/.aws/config;
        type = types.path;
      };
    };

    profile = mkOption {
      default = "default";
      type = types.string;
    };

    account = mkOption {
      default = 0;
    };

    access-key = mkOption {
      default = "";
    };

    secret-key = mkOption {
      default = "";
    };

    region = mkOption {
      default = "";
      type = types.string;
    };
  };

  # TODO env types -> local or managed
  config = mkIf (cfg.aws.enabled && cfg.environment.isLocal) (mkMerge [
    ({
      checks = ["Enabling AWS config module"];

      packages = [
        pkgs.rsync
        pkgs.awscli
        pkgs.aws-iam-authenticator
      ];
    })

    (mkIf credentials-exists 
      (let
        ini = (pkgs.lib.parseINI credentials-location);
        profile = builtins.getAttr cfg.aws.profile ini;
      in
      {
        aws.access-key = profile.aws_access_key_id;
        aws.secret-key = profile.aws_secret_access_key;
      }))

    (mkIf config-exists 
      (let
        ini = (pkgs.lib.parseINI config-location);
        profile = builtins.getAttr cfg.aws.profile ini;
      in
      {
        infos = [
          "Setting AWS region as ${profile.region}"
        ];
        aws.region = profile.region;
      }))

    (mkIf (!credentials-exists) {
      warnings = [
        "There is no AWS credentials - run aws configure or provide access key and secret key to config"
      ];
    })

    (mkIf (!config-exists) {
      warnings = [
        "AWS Config is missing, using default region: ${cfg.aws.region}"
      ];
    })
  ]);
}