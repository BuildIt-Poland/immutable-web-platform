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
  eks-ns = "eks";
  kn-serving = namespace.knative-serving;
  istio-ns = namespace.istio;
  functions-ns = namespace.functions;
in
{
  imports = with kubenix.modules; [ 
    istio-service-mesh
  ];

  kubernetes.network-mesh = {
    enable = true;

    crd = {
      certmanager.enabled = true;
    };

    namespace = {
      metadata.annotations = {
        "iam.amazonaws.com/allowed-roles" = "[\"${project-config.kubernetes.cluster.name}*\"]";
      };
    };

    helm = {
      gateways = {
        istio-ingressgateway = {
          sds.enabled = true;
          serviceAnnotations = {
            "certmanager.k8s.io/acme-challenge-type" = "dns01";
            # "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"; # FIXME does not work with external-dns
            "certmanager.k8s.io/acme-dns01-provider" = "aws";
            "certmanager.k8s.io/cluster-issuer" = "cert-issuer";
            "domainName" = "${project-config.project.make-sub-domain ""}";
            "external-dns.alpha.kubernetes.io/hostname" = "${project-config.project.make-sub-domain "*"}";
            "kubernetes.io/tls" = "ingress-cert";
            "kubernetes.io/tls-acme" = "true";
            "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "https";
            "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Owner=${project-config.project.author-email}";
          };
        };
      };

      global = {
        mtls.enabled = true;
        disablePolicyChecks = true;

        sds = {
          enabled = true;
          udsPath = "unix:/var/run/sds/uds_path";
          useNormalJwt = true;
        };

        controlPlaneSecurityEnabled = false;
        # most likely i dont need this gateway
        # k8sIngress.enabled = true;
        k8sIngress.enableHttps = true;
      };

      nodeagent = {
        enabled =  true;
        image =  "node-agent-k8s";
        env = {
          CA_PROVIDER =  "Citadel";
          CA_ADDR =  "istio-citadel:8060";
          VALID_TOKEN = true;
        };
      };

      certmanager.enabled = true;
      certmanager.email = project-config.project.author-email;
    };
  };
}