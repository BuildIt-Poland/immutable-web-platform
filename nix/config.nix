{
  rootFolder, 
  env,
  brigadeSharedSecret,
  aws-profiles,
  log,
  lib
}:
let
in
rec {
  inherit 
    rootFolder 
    env;

  aws-credentials = aws-profiles.default; # default aws profile

  # knative-serve = import ./modules/knative-serve.nix;
  projectName = "future-is-comming";
  version = "0.0.1";

  ssh-keys = {
    bitbucket = {
      pub = toString ~/.ssh/bitbucket_webhook.pub;
      priv = toString ~/.ssh/bitbucket_webhook;
    };
  };

  secrets = "${rootFolder}/secrets.json";

  kubernetes = {
    version = "1.13";
    namespace = {
      functions = "default";
      infra = "local-infra";
      brigade = "brigade";
      istio = "istio-system"; # TODO - done partially - does not change yet
    };
  };

  is-dev = env == "dev";

  s3 = {
    bucket = "future-is-comming-binary-store";
  };
  
  repository = {
    location = "bitbucket.org/digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative";
    git = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
  };

  brigade = {
    sharedSecret = brigadeSharedSecret;
    project-name = "digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative";
    pipeline = "${rootFolder}/pipeline/infrastructure.js"; 
  };

  docker = {
    registry = "docker.io/gatehub";
    destination = "docker://damianbaar"; # skopeo path transport://repo
  };

  info = rec {
    warnings = lib.dischargeProperties (
      lib.mkMerge [
        (lib.mkIf 
          (brigadeSharedSecret == "") 
          "You have to provide brigade shared secret to listen the repo hooks")
      ]
    );

    infos = lib.dischargeProperties (
      lib.mkMerge [
        (lib.mkIf 
          (is-dev) 
          "You are in dev mode")
      ]
    );
    printWarnings = lib.concatMapStrings log.warn warnings;
    printInfos = lib.concatMapStrings log.info infos;
  };
}