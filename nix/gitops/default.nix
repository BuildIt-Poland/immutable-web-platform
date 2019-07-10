# setup github
# https://argoproj.github.io/argo-cd/getting_started/

# 1. forward kubectl port-forward svc/argocd-server -n argocd 32000:443 > /dev/null &

# 2.
# passoword -> kubectl patch secret -n argocd argocd-secret \
#  -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" admin | tr -d ':\n')'"}}'

# 3. login -> argocd login localhost:32000 --insecure

# (take username / password from sops -> extract)
# 4. argocd repo add https://bitbucket.org/damian_baar/k8s-infra-descriptors --username <username> --password <password>

# 5. add project
# argocd app create future-is-comming \
#   --repo https://bitbucket.org/damian_baar/k8s-infra-descriptors \
#   --path '.' \
#   --dest-server https://kubernetes.default.svc \
#   --dest-namespace '*'