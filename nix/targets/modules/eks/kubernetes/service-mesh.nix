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
    # not the best flexibility - this will be included in the same yaml file
    # however it is overriding so make sense - better would be eks-service-mesh and separate file?
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
            # "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"; # FIXME does not work with external-dns
            # this should not be here - not necessary entry in route53
            # "external-dns.alpha.kubernetes.io/hostname" = "${project-config.project.make-sub-domain "*"}";
            "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Owner=${project-config.project.author-email}";
          };
        };
      };

      global = {
        # defaultNodeSelector = {
        #   "kubernetes.io/lifecycle"= "on-demand";
        # };
        sds = {
          enabled = true;
          udsPath = "unix:/var/run/sds/uds_path";
          useNormalJwt = true;
        };

        k8sIngress.gatewayName = "ingressgateway";
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