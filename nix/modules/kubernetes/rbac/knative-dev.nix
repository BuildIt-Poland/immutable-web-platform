# TODO
# apiVersion: rbac.authorization.k8s.io/v1
# kind: Role
# metadata:
#   name: knative-developer
# rules:
#   - apiGroups: ["serving.knative.dev"]
#     resources: ["services"]
#     verbs: ["get", "list", "create", "update", "delete"]
#   - apiGroups: ["serving.knative.dev"]
#     resources: ["configurations", "routes", "revisions"]
#     verbs: ["get", "list"]