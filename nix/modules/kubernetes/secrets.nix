{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  project-config,
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  brigade-ns = namespace.brigade.name;
  infra-ns = namespace.infra.name;
  functions-ns = namespace.functions.name;
  integration-modules = pkgs.integration-modules;
  sops = integration-modules.lib.sops;

  # TODO get secret by name - this is not ideal - treating json as string and applying env vars
  # FIXME add optional arguments - or not? all can be from sops
  apply-secrets = 
    let
      # INFO reference to self - with evaluated k8s resource
      secret-ref = project-config.kubernetes.resources.getByName "secrets";
    in
    pkgs.writeScriptBin "apply-secrets" ''
      ${pkgs.lib.log.important "Creating AWS secret"}
      AWS_KEY=$(${pkgs.awscli}/bin/aws configure get aws_access_key_id | base64)
      AWS_SECRET=$(${pkgs.awscli}/bin/aws configure get aws_secret_access_key | base64)

      ${pkgs.lib.log.important "Creating OAuth secret"}
      BB_KEY=$(${sops.extractSecret ["bitbucket" "key"] project-config.git-secrets.location} | base64)
      BB_SECRET=$(${sops.extractSecret ["bitbucket" "secret"] project-config.git-secrets.location} | base64)

      ${pkgs.lib.log.important "Patching ..."}
      eval "echo \"$(cat ${secret-ref.yaml.objects})\"" | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  # actually it gives a chance to avoid keeping sensitive data in descriptors
  module.scripts = [
    apply-secrets
  ];

  # TODO aws is blowing out - investigate
  # kubernetes.patches = [
  #   apply-secrets
  # ];

  kubernetes.api.secrets = {
    aws-credentials = {
      metadata = {
        namespace = infra-ns;
        name = "aws-credentials";  
      };
      type = "Opaque";
      data = {
        access_key = "$AWS_KEY";
        secret_key = "$AWS_SECRET";
      };
    };
    bitbucket-secret = {
      metadata = {
        namespace = infra-ns;
        name = "bitbucket-secret";  
      };
      type = "Opaque";
      data = {
        consumerKey = "$BB_KEY";
        consumerSecret = "$BB_SECRET";
      };
    };

    # TODO
    # hydra-ssh-key = {

    # };
  };
}
