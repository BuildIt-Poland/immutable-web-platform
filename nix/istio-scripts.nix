# TODO
# Port forward to the first istio-ingressgateway pod
kubectl -n istio-system port-forward $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath="{.items[0].metadata.name}") 15000

# Get the http routes from the port-forwarded ingressgateway pod (requires jq)
alias iroutes='curl --silent http://localhost:15000/config_dump |
jq '\''.configs.routes.dynamic_route_configs[].route_config.virtual_hosts[]|
{name: .name, domains: .domains, route: .routes[].match.prefix}'\'''
 
# Get the logs of the first istio-ingressgateway pod
# Shows what happens with incoming requests and possible errors
alias igl='kubectl -n istio-system logs $(kubectl -n istio-system get pods
-listio=ingressgateway -o=jsonpath="{.items[0].metadata.name}") --tail=300'
 
# Get the logs of the first istio-pilot pod
# Shows issues with configurations or connecting to the Envoy proxies
alias ipl='kubectl -n istio-system logs $(kubectl -n istio-system get pods
-listio=pilot -o=jsonpath="{.items[0].metadata.name}") discovery --tail=300'
