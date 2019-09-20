docker build -f functions/express-app/Dockerfile . \
  --network=host  \
  --build-arg AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
  --build-arg AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
  --build-arg AWS_DEFAULT_REGION="$(aws configure get region)"