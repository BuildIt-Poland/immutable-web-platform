{
  rootFolder, 
  env,
  brigadeSharedSecret,
  aws-profiles,
  region ? null,
  log,
  nix-gitignore,
  lib
}:
let
in
rec {
  inherit 
    rootFolder 
    env;

  aws-credentials = 
    if (env == "brigade" || !builtins.pathExists ~/.aws/credentials)
    then
      # TODO will be exported as env vars
      {

        aws_access_key_id = "";
        aws_secret_access_key = "";
        region = "";
      }
    else
    let
      aws = aws-profiles.default; # TODO add ability to change profile
    in
      if (builtins.hasAttr "region" aws)
        then aws
        else aws // { region = if region != null then region else "eu-west-2"; };

  # knative-serve = import ./modules/knative-serve.nix;
  projectName = "future-is-comming";
  version = "0.0.1";
  gitignore = nix-gitignore.gitignoreSourcePure [ "${rootFolder}/.gitignore" ];

  ssh-keys = {
    bitbucket = 
    if builtins.pathExists ~/.ssh/bitbucket_webhook
      then {
        pub = builtins.readFile toString ~/.ssh/bitbucket_webhook.pub;
        priv = builtins.readFile ~/.ssh/bitbucket_webhook;
      } else {
        pub = "";
        priv = "";
      };
  };

  repositories = {
    infra-yaml = "git@bitbucket.org:da20076774/k8s-infra-descriptors.git";
  };

  secrets = "${rootFolder}/secrets.json";

  kubernetes = {
    version = "1.13";
    namespace = {
      functions = "functions";
      infra = "local-infra";
      brigade = "brigade";
      istio = "istio-system";
      knative-monitoring = "knative-monitoring";
      knative-serving = "knative-serving";
      argo = "argocd";
    };
  };

  imagePullPolicy = "IfNotPresent";

  is-dev = env == "dev";

  s3 = {
    worker-cache = "${projectName}-worker-binary-store";
  };
  
  repository = {
    location = "bitbucket.org/digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative"; # this name cannot be longer than 64
    git = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
  };

  brigade = {
    sharedSecret = brigadeSharedSecret;
    project-name = "embracing-nix-docker-k8s-helm-knative";
    pipeline = "${rootFolder}/pipeline/infrastructure.ts"; 
  };

  # TODO change this ifs to mkIf (if dev)
  docker = rec {
    local-registry = {
      exposedPort = 32001;
    };

    namespace = env;

    registry = 
      if is-dev
        then "dev.local"
        else "docker.io/gatehub";

    destination = "docker://damianbaar"; # skopeo path transport://repo

    tag = if is-dev
      then { tag = "dev-build"; }
      else { tag = version; };
  };

  info = rec {
    warnings = lib.dischargeProperties (
      lib.mkMerge [
        (lib.mkIf 
          (!(ssh-keys.bitbucket.priv != ""))
          "Bitbucket key does not exists") 
      ]
    );

    printWarnings = lib.concatMapStrings log.warn warnings;
  };
}