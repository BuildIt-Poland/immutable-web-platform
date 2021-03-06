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
in
{
  imports = with kubenix.modules; [ 
    k8s
    k8s-extension
    bitbucket-sources
    knative-serve
  ];

  config = {
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
              imagePullPolicy = "IfNotPresent";
            }];
          };
        };
      };
    };

    # TODO system:serviceaccount:knative-sources:bitbucket-controller-manager
    # list resource \"pipelineruns\" in API group \"tekton.dev\" in the namespace \"dev-infra\""}

    ## ROLE BINDING
    kubernetes.api.clusterrolebindings = 
      let
        admin = "tekton-pipeline-runner";
      in
      {
        "${admin}" = {
          metadata = {
            name = "${admin}";
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            name = "cluster-admin"; # TODO this is too much in case of privilages
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = "bitbucket-controller-manager";
              namespace = "knative-sources";
            }
          ];
        };
      };

# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: default-ch-webhook
#   namespace: knative-eventing
# data:
#   default-ch-config: |
#     clusterDefault:
#       apiVersion: messaging.knative.dev/v1alpha1
#       kind: InMemoryChannel
#     namespaceDefaults:
#       some-namespace:
#         apiVersion: messaging.knative.dev/v1alpha1
#         kind: KafkaChannel
#         spec:
#           numPartitions: 2
#           replicationFactor: 1

# ERROR "No callback uri defined for the OAuth client.
    kubernetes.api.bitbucketsource.channel-repo = {
      metadata = {
        name = "bitbucket-source-sample";
        namespace = infra-ns.name;
      };
      spec = {
        # serviceAccount = "bb-source";
        eventTypes = [
          "repo:push"
          # "repo:commit_status_created"
        ];
        # FIXME project-config code repository
        ownerAndRepository = "digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative";
        # ownerAndRepository = "damian_baar/k8s-infra-descriptors";
        consumerKey = {
          secretKeyRef.name = "bitbucket-secret";
          secretKeyRef.key = "consumerKey";
        };
        consumerSecret = {
          secretKeyRef.name = "bitbucket-secret";
          secretKeyRef.key = "consumerSecret";
        };
        sink = {
          # apiVersion = "messaging.knative.dev/v1alpha1";
          # kind = "Channel";
          # name = "githubchannel";
          apiVersion = "serving.knative.dev/v1alpha1";
          kind = "Service";
          name = "bitbucket-message-dumper";
        };
      };
    };
    kubernetes.api.kchannel.channel-repo = {
      metadata = {
        name = "githubchannel";
        namespace = infra-ns.name;
      };
      spec = {
        channelTemplate = {
          apiVersion = "messaging.knative.dev/v1alpha1";
          kind = "InMemoryChannel";
        };
      };
    };
  };
}