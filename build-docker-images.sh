echo "Run this script within nix-shell"

echo "Setup worker"
# source < curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave

echo "Cooking image"
nix-build nix -A functions.express-app.images --builders 'ssh://nix-docker-build-slave x86_64-linux' --arg use-docker true --max-jobs 100

echo "Push to local cluster"
# here should be run with appropriate builder to get correct image path
push-to-local-registry