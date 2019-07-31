nix-build ./nix/development.nix -A docker
docker load -i result
dgoss run -e "TARGET=dgoss" dev.local/express-app:dev-build