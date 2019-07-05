
`knctl curl -s express-app -n functions`

`hey -z 30s -c 100 \
-host "express-app.functions.example.com" "http://localhost:$KUBE_NODE_PORT?sleep=100&prime=10000&bloat=5"`