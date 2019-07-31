# TODO share nix-store
docker run --privileged -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/source -it lnl7/nix:ssh  bash
# within docker nix-build /source/infra/test.nix -A docker

# nix-serve
# nix-build /source/infra/test.nix -A docker --store http://host.docker.internal:5000