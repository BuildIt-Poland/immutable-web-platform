## this should be a module with options
# {pkgs}:
# with pkgs;
# {
#   buildInputs = [
#     # js
#     nodejs
#     yarn2nix.yarn
#     terraform-with-plugins

#     # tools
#     kind
#     docker
#     knctl
#     brigade
#     brigadeterm

#     # secrets
#     sops

#     # cluster scripts
#     k8s-local.delete-local-cluster
#     k8s-local.create-local-cluster-if-not-exists
#     k8s-local.expose-istio-ingress
#     k8s-local.add-knative-label-to-istio

#     # waits
#     k8s-local.wait-for-istio-ingress
#     k8s-local.wait-for-brigade-ingress

#     # ingress & tunnels
#     k8s-local.expose-istio-ingress
#     k8s-local.expose-brigade-gateway
#     k8s-local.create-localtunnel-for-brigade

#     # exports
#     k8s-local.export-kubeconfig
#     k8s-local.export-ports

#     # overridings
#     k8s-local.curl-with-resolve

#     # helm
#     k8s-cluster-operations.apply-cluster-stack
#     k8s-cluster-operations.apply-functions-to-cluster
#     k8s-cluster-operations.push-docker-images-to-local-cluster

#     # help
#     get-help
#   ];

#   bootstrap = ''
#     ${log.message "Hey sailor!"}
#     ${log.info "If you need any help, run 'get-help'"}

#     ${env-config.info.printWarnings}
#     ${env-config.info.printInfos}

#     ${if fresh then "delete-local-cluster" else ""}

#     create-local-cluster-if-not-exists
#     source export-kubeconfig

#     push-docker-images-to-local-cluster
#     apply-cluster-stack
#     apply-functions-to-cluster

#     source export-ports

#     wait-for-istio-ingress
#     add-knative-label-to-istio
#     expose-istio-ingress

#     get-help
#   '';
# }