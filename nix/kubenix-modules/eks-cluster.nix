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

  update-eks-vpc-cni = 
    pkgs.writeScriptBin "apply-aws-credentails-secret" ''
      ${pkgs.lib.log.important "Patching AWS VPC CNI"}

      ${pkgs.kubectl}/bin/kubectl patch daemonset aws-node \
        -n kube-system \
        -p '{"spec": {"template": {"spec": {"containers": [{"image": "602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni:v1.5.1-rc1","name":"aws-node"}]}}}}'
    '';

  # https://knative.dev/docs/serving/tag-resolution/
  # https://github.com/knative/serving/issues/4435#issuecomment-504108797 
  # https://github.com/knative/serving/pull/4084
  knative-not-resolve-tags =
    pkgs.writeScriptBin "knative-not-resolve-tags" ''
      ${pkgs.lib.log.important "Patching Knative serving"}

      ${pkgs.kubectl}/bin/kubectl patch configmap config-deployment \
        -n ${kn-serving} \
        -p '{"data":{"registriesSkippingTagResolving":"${project-config.aws.account}.dkr.ecr.${project-config.aws.region}.amazonaws.com/${project-config.kubernetes.cluster.name}"}}'
    '';

  # aws route53 list-hosted-zones-by-name --output json --dns-name "local-future-is-comming.io" | jq -r '.HostedZones[0].Id
  create-cr = kind: resource: {
    inherit kind resource;

    group = "certmanager.k8s.io";
    version = "v1alpha1";
    description = "";
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    helm
  ];

  kubernetes.patches = [
    update-eks-vpc-cni
    knative-not-resolve-tags
  ];

  kubernetes.api.namespaces."${eks-ns}"= {};
 
   # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md
  kubernetes.helm.instances.eks-cluster-autoscaler = {
    namespace = "${eks-ns}";
    chart = k8s-resources.cluster-autoscaler;
    values = {
      rbac.create = "true";
      cloudProvider = "aws";
      sslCertPath =  "/etc/ssl/certs/ca-bundle.crt"; # it is necessary in case of EKS
      awsRegion = project-config.aws.region;
      autoDiscovery = {
        clusterName = "${project-config.kubernetes.cluster.name}";
        enabled = true;
      };
      nodeSelector = {
        "kubernetes.io/lifecycle"= "on-demand";
      };
    };
  };

  # crd -> https://github.com/helm/charts/blob/master/stable/external-dns/templates/crd.yaml
  # example: https://github.com/kubernetes-incubator/external-dns/blob/master/docs/contributing/crd-source/dnsendpoint-example.yaml
  kubernetes.helm.instances.external-dns = {
    namespace = "${eks-ns}";
    chart = k8s-resources.external-dns;
    values = {
      provider = "aws"; 
      istioIngressGateways = [
        "istio-system/istio-ingressgateway"
      ];
      sources = ["service" "ingress" "istio-gateway"];
      rbac.create = true;
      policy = "upsert-only";
      logLevel = "debug";
      aws = {
        region = project-config.aws.region;
      };
      domainFilters = [project-config.project.domain];
      # annotationFilter="type=external";
      # crd.create = true;
    };
  };

  kubernetes.api.cert-manager-certificates = {
    ingress-cert = 
    let
      mk-domain = project-config.project.make-sub-domain;
    in
    {
      metadata = {
        namespace = istio-ns;
        name = "ingress-cert";
      };
      spec = {
        secretName = "ingress-cert";
        issuerRef = {
          # name = "letsencrypt-${if project-config.environment.type != "prod" then "staging" else "prod"}";
          name = "cert-issuer";
          kind = "ClusterIssuer";
        };
        commonName = "${mk-domain "*"}";
        dnsNames = [ 
          (mk-domain "*") 
        ];
        acme.config = [
          { http01.ingressClass = "istio";
            domains = [ 
              (mk-domain "*")
            ];
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
            route53.region = project-config.aws.region; 
          }];
        };
      };
    };
  };

  # TODO helm stable/k8s-spot-termination-handler
  # TODO https://github.com/helm/charts/tree/master/stable/kube2iam

  kubernetes.customResources = [
    (create-cr "Certificate" "cert-manager-certificates")
    (create-cr "ClusterIssuer" "cert-manager-issuer")
  ];
}
