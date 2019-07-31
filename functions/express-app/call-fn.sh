curl '-sS' '-H' 'Host: express-app.functions.dev.cluster' http://$(minikube ip -p $PROJECT_NAME):31380 -v
