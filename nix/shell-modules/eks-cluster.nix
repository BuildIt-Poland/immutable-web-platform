{config, pkgs, lib, inputs, ...}:
with lib;
let
  cfg = config;

  cluster-name = config.kubernetes.cluster.name;
  terraform-kubeconfig-path = "${config.terraform.location}/aws/cluster/.kube/kubeconfig_${cluster-name}";
  registry-path = "${config.aws.account}.dkr.ecr.${config.aws.region}.amazonaws.com";

  # https://docs.aws.amazon.com/cli/latest/reference/ecr/get-authorization-token.html
  get-authorization-token  = pkgs.writeScript "get-authorization-token" ''
    ${pkgs.awscli}/bin/aws ecr get-authorization-token \
      --output text --query 'authorizationData[].authorizationToken' \
      | base64 --decode
  '';

  push-to-docker-registry = 
    let
      images = pkgs.k8s-operations.docker-images (desc: 
        let docker = desc.value; in ''
          ${log.info "Pushing docker image, for ${desc.name} to ${config.docker.registry}: ${docker.name}:${docker.tag}, ${docker.image}"}

          ${pkgs.skopeo}/bin/skopeo copy \
            docker-archive:${docker.image} \
            docker://${config.docker.registry}/${cluster-name}:${docker.tag} \
            --dest-creds=$token
        '');
    in 
      pkgs.writeScriptBin "push-to-docker-registry" ''
        token="$(${get-authorization-token})"
        ${images}
    '';
in
with lib;
rec {
  options.eks-cluster = {
    enable = mkOption {
      default = true;
    };
    configuration = {
      bastion = mkOption {
        default = "";
      };
    };
  };

  config = mkIf cfg.eks-cluster.enable (mkMerge [
    { checks = ["Enabling eks module"]; }

    ({
      packages = with pkgs; [];

      storage.provisioner = "ceph.rook.io/block";

      environment.vars = {
        KUBECONFIG = terraform-kubeconfig-path;
        DOCKER_REGISTRY = registry-path;
      };

      load-balancer.service-annotations = name: {
        domainName = cfg.project.make-sub-domain "";
        # "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"; # FIXME does not work with external-dns
        "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Owner=${cfg.project.author-email}";
        "external-dns.alpha.kubernetes.io/hostname" = "${cfg.project.make-sub-domain "*"}";
        # "certmanager.k8s.io/acme-challenge-type" = "dns01";
        # "certmanager.k8s.io/acme-dns01-provider" = "aws";
        # "kubernetes.io/tls-acme" = "true";
        # "kubernetes.io/tls" = "ingress-cert";
        # "certmanager.k8s.io/cluster-issuer" = "cert-issuer";
      };

      docker = {
        namespace = mkForce cluster-name;
        tag = mkForce cfg.project.hash;

        registry = mkForce registry-path;
        destination = "docker://${registry-path}";
      };

      kubernetes = {
        imagePullPolicy = "IfNotPresent";
      };
    })

    (mkIf cfg.docker.upload {
      packages = with pkgs; [
        push-to-docker-registry
      ];

      actions.queue = [{ 
        priority = cfg.actions.priority.docker; 
        action = ''
          push-to-docker-registry
        '';
      }];
    })
  ]);
}