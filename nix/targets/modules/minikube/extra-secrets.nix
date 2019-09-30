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
      withLocalhost = knative-services ++ ["localhost"];
    in
    pkgs.writeScriptBin "apply-tls-secrets" ''
      ${pkgs.lib.log.important "Creating TLS istio secret"}

      ip=$(minikube ip)
      domain=$ip.nip.io

      domains="$domain ${lib.concatStringsSep " " (builtins.map (x: "${x}.$domain") withLocalhost)}"
      length=${toString (builtins.length withLocalhost)}

      tmpfile=$(mktemp -d)
      (cd $tmpfile && ${pkgs.mkcert}/bin/mkcert $domains)

      TLS_CERT=$(cat $tmpfile/$domain+$length-key.pem | base64 | tr -d '\n') 
      TLS_KEY=$(cat $tmpfile/$domain+$length.pem | base64 | tr -d '\n') 

      ${pkgs.lib.log.important "Patching ..."}
      eval "echo \"$(cat ${secret-ref.yaml.objects})\"" | ${pkgs.kubectl}/bin/kubectl apply -f -

      ${pkgs.lib.log.important "Run 'mkcert -install' to enable ssl in localhost"}
    '';
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
  ];

  kubernetes.patches = [
    apply-secrets
  ];

  kubernetes.api.secrets = {
    istio-ingress = {
      metadata = {
        namespace = "istio-system";
        name = "istio-ingressgateway-certs";  
      };
      type = "kubernetes.io/tls";
      data = {
        "tls.cert" = "$TLS_CERT";
        "tls.key" = "$TLS_KEY";
      };
    };
  };
}
