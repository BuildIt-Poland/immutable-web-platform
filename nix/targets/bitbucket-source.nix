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
    # kubernetes.api.ksvc.bitbucket-message-dumper = {
    #   metadata = {
    #     name = "bitbucket-message-dumper";
    #     namespace = infra-ns.name;
    #   };
    #   spec = {
    #     runLatest.configuration.build = {
    #       apiVersion = "tekton.dev/v1alpha1";
    #       kind =  "PipelineRun";
    #       metadata.labels = {
    #         app =  "health";
    #         component =  "frontend";
    #         tag =  "__TAG__";
    #       };
    #       spec = {
    #         pipelineRef = {
    #           name = "build-and-deploy-pipeline";
    #         };
    #       };
    #     };
    #     # template = {
    #     #   spec = {
    #     #     containers = [{
    #     #       image = "gcr.io/knative-releases/github.com/knative/eventing-sources/cmd/message_dumper";
    #     #       # imagePullPolicy = project-config.kubernetes.imagePullPolicy;
    #     #       imagePullPolicy = "IfNotExists";
    #     #     }];
    #     #   };
    #     # };
    #   };
    # };

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
          apiVersion = "tekton.dev/v1alpha1";
          kind =  "PipelineRun";
          metadata.labels = {
            app =  "health";
            component =  "frontend";
            tag =  "__TAG__";
          };
          spec = {
            pipelineRef = {
              name = "build-and-deploy-pipeline";
            };
          };
          # apiVersion = "serving.knative.dev/v1alpha1";
          # kind = "Service";
          # name = "bitbucket-message-dumper";
        };
      };
    };
  };
}