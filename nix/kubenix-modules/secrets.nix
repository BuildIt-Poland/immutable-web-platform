{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  project-config,
  ... 
}:
let
  save-aws-credentials-secret = 
    let
      # reference to self - with evaluated k8s resource
      secret-ref = project-config.kubernetes.resources.getByName "secrets";
    in
    pkgs.writeScriptBin "save-aws-credentails-secret" ''
      cat ${secret-ref.yaml.objects} 
    '';
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  module.scripts = [
    save-aws-credentials-secret
  ];

  kubernetes.api.secrets = {
    aws-credentials = {
      metadata = {
        name = "aws-secret";  
      };
      type = "Opaque";
      data = {
        access-key = "";
        secret-key = "";
      };
    };
  };
}
