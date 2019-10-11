docker build -f functions/express-app/Dockerfile . \
  --network=host  \
  --build-arg ssh_prv_key="$(cat ~/.ssh/id_rsa)" \
  --build-arg ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)" \
  --build-arg AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
  --build-arg AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
  --build-arg AWS_DEFAULT_REGION="$(aws configure get region)"