# setup github
# https://argoproj.github.io/argo-cd/getting_started/

# 1. password patch -> 
kubectl patch secret -n argocd argocd-secret \
 -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" admin | tr -d ':\n')'"}}'

# 2. login -> (admin/admin)
argocd login $(mk ip):31200 --insecure

# 3. if want to play with extrnal repo
ARGO_PASS=$(cat secrets.json | sops  --input-type json -d --extract '["bitbucket"]["pass"]' -d /dev/stdin)
ARGO_USER=$(cat secrets.json | sops  --input-type json -d --extract '["bitbucket"]["user"]' -d /dev/stdin)
argocd repo add https://bitbucket.org/damian_baar/k8s-infra-descriptors --username $ARGO_USER --password $ARGO_PASS

# 4. add project

argocd app create $PROJECT_NAME \
  --dest-server https://kubernetes.default.svc \
  --repo https://bitbucket.org/damian_baar/k8s-infra-descriptors \
  --path '.' \
  --dest-namespace 'default' # check this - is not happy for rbac


# argocd app sync $PROJECT_NAME --local ./resources
# argocd app diff $PROJECT_NAME --local ./resources