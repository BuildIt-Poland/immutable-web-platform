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
  brigade-ns = namespace.brigade;

  apply-aws-credentials-secret = 
    let
      # INFO reference to self - with evaluated k8s resource
      secret-ref = project-config.kubernetes.resources.getByName "secrets";
    in
    pkgs.writeScriptBin "apply-aws-credentails-secret" ''
      ${pkgs.lib.log.important "Creating AWS secret"}
      AWS_KEY=$(aws configure get aws_access_key_id | base64)
      AWS_SECRET=$(aws configure get aws_secret_access_key | base64)

      eval "echo \"$(cat ${secret-ref.yaml.objects})\"" | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  # actually it gives a chance to avoid keeping sensitive data in descriptors
  kubernetes.patches = [
    apply-aws-credentials-secret
  ];

  kubernetes.api.secrets = {
    aws-credentials = {
      metadata = {
        namespace = brigade-ns;
        name = "aws-credentials";  
      };
      type = "Opaque";
      data = {
        access_key = "$AWS_KEY";
        secret_key = "$AWS_SECRET";
      };
    };
  };

  # TODO sharedSecret (brigadeSharedSecret) - included in secrets.json
  # TODO git clone key - sshKey
}
