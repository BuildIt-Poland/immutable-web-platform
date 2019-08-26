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

  kubernetes.annotations = {
    instance-on-demand = {"kubernetes.io/lifecycle"= "on-demand";};
  };

  kubernetes.api.namespaces."${eks-ns}"= {
    metadata.annotations = {
      "iam.amazonaws.com/allowed-roles" = "[\"${project-config.kubernetes.cluster.name}*\"]";
    };
  };
 
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
      nodeSelector = config.kubernetes.annotations.instance-on-demand;
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

  kubernetes.helm.instances.kube2iam = {
    namespace = "${eks-ns}";
    chart = k8s-resources.kube2iam;
    values = {
      rbac.create = true;
    };
  };

  # actually it make sense to have issuer and manager here
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
          # name = "letsencrypt${if project-config.environment.type != "prod" then "-staging" else ""}";
          name = "cert-issuer";
          kind = "ClusterIssuer";
        };
        commonName = "${mk-domain "*"}";
        dnsNames = [ 
          (mk-domain "*") 
        ];
        acme.config = [
          { dns01.provider = "route53";
            domains = [ 
              (mk-domain "*")
            ];
          }
        ];
        };
      };
    };
  # orders controller: Re-queuing item "istio-system/ingress-cert-780260723" due to error processing: Error constructing Challenge resource for Authorization: ACME server does not allow selected challenge type or no provider is configured for domain "future-is-comming.dev.buildit.consulting"
  /*
  E0824 12:35:17.852569       1 controller.go:207] challenges controller: Re-queuing item "istio-system/ingress-cert-3852624261-0" due to error processing: Failed to determine Route 53 hosted zone ID: AccessDenied: User: arn:aws:sts::006393696278:assumed-role/future-is-comming-cluster20190823155558805300000007/i-07df057b5997f8b27 is not authorized to perform: route53:ListHostedZonesByName
	status code: 403, request id: b3b608da-02b5-4d6d-b411-b54c079dce69
  */
  kubernetes.api.cert-manager-issuer = {
    ingress-cert =  {
      metadata = {
        name = "cert-issuer";
        annotations = {
          # take from terraform or define upfront
          # "iam.amazonaws.com/role" = "arn:aws:iam::006393696278:role/future-is-comming-cluster20190823155558805300000007";
          
        };
        # Annotate your pods with iam.amazonaws.com/role: <role arn> and apply changes
  # FIXME create in terraform or take from workers from now
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

  # https://github.com/knative/docs/blob/master/docs/serving/using-a-custom-domain.md#apply-from-a-file
  # kubernetes.api.configmaps = {
  #   knative-domain = {
  #     metadata = {
  #       name = "config-certmanager";
  #       # namespace = "${kn-serving}";
  #       namespace = "knative-serving";
  #       labels = {
  #         "networking.knative.dev/certificate-provider" = "cert-manager";
  #       };
  #     };
  #     data = {
  #       secretName = "ingress-cert";
  #       issuerRef = ''
  #         name: cert-issuer
  #         kind: ClusterIssuer
  #       '';
  #       # autoTLS = "Enabled";
  #       # httpProtocol = "Redirected";
  #       solverConfig = ''
  #         dns01:
  #           provider: route53
  #       '';
  #     };
  #   };
  # };

  # FIXME helm stable/k8s-spot-termination-handler

  kubernetes.customResources = [
    (create-cr "Certificate" "cert-manager-certificates")
    (create-cr "ClusterIssuer" "cert-manager-issuer")
  ];
}
