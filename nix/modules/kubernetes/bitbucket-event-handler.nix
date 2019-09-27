{ 
  config, 
  lib, 
  kubenix, 
  k8s-resources,
  project-config, 
  ... 
}:
with kubenix.lib.helm;
let
  namespace = project-config.kubernetes.namespace;
  functions-ns = namespace.functions;
  infra-ns = namespace.infra;
  knative-ns = namespace.knative-serving;

  create-cr = kind: {
    inherit kind;

    group = "sources.nachocano.org";
    version = "v1alpha1";
    description = "";
    resource = lib.toLower kind;
  };
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    knative-serve
  ];

  config = {
    kubernetes.api.namespaces."${infra-ns.name}"= {
      metadata = lib.recursiveUpdate {} infra-ns.metadata;
    };

    kubernetes.api.ksvc.bitbucket-message-dumper = {
      metadata = {
        name = "bitbucket-message-dumper";
        namespace = infra-ns.name;
      };
      spec = {
        template = {
          spec = {
            containers = [{
              image = "gcr.io/knative-releases/github.com/knative/eventing-sources/cmd/message_dumper";
              imagePullPolicy = project-config.kubernetes.imagePullPolicy;
            }];
          };
        };
      };
    };

    kubernetes.api.bitbucketsource.channel-repo = {
      metadata = {
        name = "bitbucket-source-sample";
        namespace = infra-ns.name;
      };
      spec = {
        eventTypes = [
          "repo:push"
          "repo:commit_status_created"
        ];
        # FIXME project-config code repository
        ownerAndRepository = "digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative";
        consumerKey = {
          secretKeyRef.name = "bitbucket-secret";
          secretKeyRef.key = "consumerKey";
        };
        consumerSecret = {
          secretKeyRef.name = "bitbucket-secret";
          secretKeyRef.key = "consumerSecret";
        };
        sink = {
          apiVersion = "serving.knative.dev/v1alpha1";
          kind = "Service";
          name = "bitbucket-message-dumper";
        };
      };
    };

    kubernetes.customResources = [
      (create-cr "BitBucketSource")
    ];
  };
}