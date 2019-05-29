{
  rootFolder, 
  env,
  brigadeSharedSecret
}:
rec {
  inherit rootFolder env;

  # knative-serve = import ./modules/knative-serve.nix;
  projectName = "future-is-comming";
  version = "0.0.1";
  ports = {
    istio-ingress = "32632";
  };

  ssh-keys = {
    bitbucket = {
      pub = toString ~/.ssh/bitbucket_webhook.pub;
      priv = toString ~/.ssh/bitbucket_webhook;
    };
  };

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
}