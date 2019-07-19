#### Debugging - within `nixos`
* `systemctl cat container@database.service`
* `systemctl status container@database.service`
* `systemctl status test-service`
* just to have wrapping `systemctl status --no-pager --full`


#### Istio
* https://istio.io/docs/ops/traffic-management/proxy-cmd/
* kubectl -n istio-system exec -it -c istio-proxy virtual-services-b558c6f4d-rdrgn bash
* curl localhost:15000/help