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
  create-tls-certificates = 
    let
      # INFO reference to self - with evaluated k8s resource
      # this reference to custom-secrets is so so ...
      secret-ref = project-config.kubernetes.resources.getByName "extra_secrets";

      # TODO create selector library
      kpath = ["raw" "kubernetes" "api" "ksvc"];
      has-knative-path = lib.hasAttrByPath kpath;
      get-knative-path = lib.getAttrFromPath kpath;
      getKnativeServices = 
        d: 
          let
            withKnativeService = lib.filterAttrs (n: has-knative-path) d;
            knative-services = 
              lib.mapAttrs 
                (n: v: (builtins.attrNames (get-knative-path v))) 
                withKnativeService;
          in
            lib.flatten (builtins.attrValues knative-services);

      knative-services = getKnativeServices project-config.modules.kubernetes;
      # so so
      withLocalhost = (builtins.map (x: "${x}.${functions-ns}") knative-services) ++ ["localhost"];
    in
    pkgs.writeScriptBin "apply-tls-secrets" ''
      ${pkgs.lib.log.important "Creating TLS istio secret"}

      ip=$(get-istio-ingress-lb)
      domain=$ip.nip.io

      domains="$domain ${lib.concatStringsSep " " (builtins.map (x: "${x}.$domain") withLocalhost)}"
      length=${toString (builtins.length withLocalhost)}

      tmpfile=$(mktemp -d)
      (cd $tmpfile && ${pkgs.mkcert}/bin/mkcert $domains)

      TLS_CERT=$(cat $tmpfile/$domain+$length-key.pem | base64 | tr -d '\n') 
      TLS_KEY=$(cat $tmpfile/$domain+$length.pem | base64 | tr -d '\n') 

      ${pkgs.lib.log.important "Creating OAuth secret"}
      BB_KEY=$(${sops.extractSecret ["bitbucket" "key"] project-config.git-secrets.location} | base64)
      BB_SECRET=$(${sops.extractSecret ["bitbucket" "secret"] project-config.git-secrets.location} | base64)

      ${pkgs.lib.log.important "Creating Bitbucket secret"}
      BB_USER=$(${sops.extractSecret ["bitbucket" "user"] project-config.git-secrets.location})
      BB_PASS=$(${sops.extractSecret ["bitbucket" "pass"] project-config.git-secrets.location})

      echo $BB_USER
      echo $BB_PASS

      ${pkgs.lib.log.important "Patching ..."}
      eval "echo \"$(cat ${secret-ref.yaml.objects})\"" | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

 # kubernetes.patches = [
  module.scripts = [
    create-tls-certificates
  ];

  # TODO recreate in many namespaces?
  kubernetes.api.secrets = {
    istio-ingress = {
      metadata = {
        namespace = "istio-system";
        name = "istio-ingressgateway-certs";  
      };
      type = "kubernetes.io/tls";
      data = {
        "tls.crt" = "$TLS_CERT";
        "tls.key" = "$TLS_KEY";
      };
    };

    bitbucket-secret = {
      metadata = {
        namespace = infra-ns;
        # namespace = "knative-sources";
        # name = "bitbucket-secret";  
      };
      type = "Opaque";
      data = {
        consumerKey = "$BB_KEY";
        consumerSecret = "$BB_SECRET";
      };
    };
    # https://github.com/tektoncd/pipeline/blob/master/docs/auth.md
    bitbucket-basic-auth = {
      metadata = {
        name = "bitbucket-basic-auth";  
        annotations = {
          "tekton.dev/git-0" = "https://bitbucket.org";
        };
      };
      type = "kubernetes.io/basic-auth";
      stringData = {
        password = "$BB_PASS";
        username = "$BB_USER";
      };
    };
  };
}
