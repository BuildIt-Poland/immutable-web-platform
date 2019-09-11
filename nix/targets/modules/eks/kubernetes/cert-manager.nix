# https://eksworkshop.com/scaling/deploy_hpa/
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources ? pkgs.k8s-resources,
  project-config,
  ... 
}:
let
  namespace = project-config.kubernetes.namespace;
  istio-ns = namespace.istio.name;
  argo-ns = namespace.argo.name;
  functions-ns = namespace.functions.name;

  create-cr = kind: resource: {
    inherit kind resource;

    group = "certmanager.k8s.io";
    version = "v1alpha1";
    description = "";
  };
in
{
  imports = with kubenix.modules; [ 
  ];

  # actually it make sense to have issuer and manager here
  kubernetes.api.cert-manager-certificates = 
    let
      project = project-config.project;
      mk-domain = project.make-sub-domain;
      subdomains = builtins.map mk-domain project.subdomains;
    in
    {
      ingress-cert = {
        metadata = {
          namespace = istio-ns;
          name = "ingress-cert";
        };
        spec = {
          secretName = "ingress-cert";
          issuerRef = {
            name = "cert-issuer";
            kind = "ClusterIssuer";
          };
          dnsNames = subdomains;
          acme.config = [
            { dns01.provider = "route53";
              domains = subdomains;
            }
          ];
          };
        };
        argocd-cert = {
          metadata = {
            namespace = argo-ns;
            name = "argo-cd-cert";
          };
          spec = {
            secretName = "argocd-secret";
            issuerRef = {
              name = "cert-issuer";
              kind = "ClusterIssuer";
            };
            dnsNames = [(mk-domain "*.services")]; # dont want to have separate certificate
            acme.config = [
              { dns01.provider = "route53";
                domains = [(mk-domain "*.services")];
              }
            ];
          };
        };
      };

  kubernetes.api.cert-manager-issuer = {
    ingress-cert =  {
      metadata = {
        name = "cert-issuer";
      };
      spec = {
        acme = {
          server = "https://acme-v02.api.letsencrypt.org/directory";
          email = project-config.project.author-email;
          privateKeySecretRef.name = "cert-prod";
          dns01.providers = [{ 
            name = "route53"; 
            route53 = {
              region = project-config.aws.region; 
            };
          }];
        };
      };
    };
  };

  kubernetes.customResources = [
    (create-cr "Certificate" "cert-manager-certificates")
    (create-cr "ClusterIssuer" "cert-manager-issuer")
  ];
}