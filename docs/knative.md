### minikube tunnel
* attaching load balancer for istio ingress

### patching ssl
as domain based on `tunnel` there is a separate command for this
* run `patch-knative-nip-domain`

### exposing endpoint
* i.e. `create-localtunnel -l=bitbucket-message-dumper.dev-functions.10.111.182.189.nip.io`