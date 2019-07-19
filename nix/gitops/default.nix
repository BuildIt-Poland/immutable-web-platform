# setup github
# https://argoproj.github.io/argo-cd/getting_started/

# 1. forward  - listen on 31200 port
# kubectl port-forward svc/argocd-server -n argocd 32000:443 > /dev/null &

# kubectl port-forward svc/argocd-server -n argocd 32000:443 --stderrthreshold=0  > /dev/null 2>&1 &

# 2. password patch -> 
kubectl patch secret -n argocd argocd-secret \
 -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" admin | tr -d ':\n')'"}}'

# 3. login -> (admin/admin)
argocd login localhost:31200 --insecure

# 4. add repo
ARGO_PASS=$(cat secrets.json| sops  --input-type json -d --extract '["bitbucket"]["pass"]' -d /dev/stdin)
ARGO_USER=$(cat secrets.json| sops  --input-type json -d --extract '["bitbucket"]["user"]' -d /dev/stdin)
argocd repo add https://bitbucket.org/damian_baar/k8s-infra-descriptors --username $ARGO_USER --password $ARGO_PASS

# 5. add project
# TODO add prune
argocd app create future-is-comming \
  --repo https://bitbucket.org/damian_baar/k8s-infra-descriptors \
  --path '.' \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace 'default' # check this - is not happy for rbac


# argocd app sync $PROJECT_NAME --local ./resources
# argocd app diff $PROJECT_NAME --local ./resources